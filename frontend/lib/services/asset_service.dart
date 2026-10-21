import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/asset_model.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/config/api_config.dart'; // adjust to wherever ApiConfig actually lives

class AssetServiceException implements Exception {
  final String message;
  AssetServiceException(this.message);
  @override
  String toString() => message;
}

class AssetListResult {
  final List<Asset> assets;
  final InventorySummary summary;
  final List<String> categories;
  const AssetListResult(this.assets, this.summary, this.categories);
}

class AssetService {
  AssetService._();
  static final AssetService instance = AssetService._();

  static const String _path = 'admin/inventory.php'; // relative to ApiConfig.baseUrl

Map<String, String> get _headers => {
      'Content-Type': 'application/json',
    };

  Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw AssetServiceException(body['message']?.toString() ?? 'Request failed (${res.statusCode}).');
    }
    return body;
  }

  Future<AssetListResult> fetchAssets({
    String search = '',
    String category = '',
    String stockFilter = 'all', // all | in_stock | low_stock | out_of_stock
  }) async {
    final uri = ApiConfig.endpoint(_path).replace(queryParameters: {
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (category.isNotEmpty) 'category': category,
      'stock_filter': stockFilter,
    });
    final res = await http.get(uri, headers: _headers).timeout(ApiConfig.timeout);
    final body = _decode(res);
    final assets = (body['data'] as List<dynamic>? ?? [])
        .map((e) => Asset.fromJson(e as Map<String, dynamic>))
        .toList();
    final summary = body['summary'] != null
        ? InventorySummary.fromJson(body['summary'] as Map<String, dynamic>)
        : InventorySummary.empty;
    final categories = (body['categories'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    return AssetListResult(assets, summary, categories);
  }

  Future<List<StockMovement>> fetchMovements({int? productId, int limit = 100}) async {
    final uri = ApiConfig.endpoint(_path).replace(queryParameters: {
      'action': 'movements',
      'limit': '$limit',
      if (productId != null) 'product_id': '$productId',
    });
    final res = await http.get(uri, headers: _headers).timeout(ApiConfig.timeout);
    final body = _decode(res);
    return (body['data'] as List<dynamic>? ?? [])
        .map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InventoryAlert>> fetchAlerts() async {
    final uri = ApiConfig.endpoint(_path).replace(queryParameters: {'action': 'alerts'});
    final res = await http.get(uri, headers: _headers).timeout(ApiConfig.timeout);
    final body = _decode(res);
    return (body['data'] as List<dynamic>? ?? [])
        .map((e) => InventoryAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  int? get _currentUserId => int.tryParse(SessionService.instance.currentUser?.id ?? '');

  /// action: add | remove | set | sale | return
  Future<int> adjustStock({
    required int productId,
    required String action,
    int quantity = 0,
    String? notes,
  }) async {
    final res = await http
        .post(
          ApiConfig.endpoint(_path),
          headers: _headers,
          body: jsonEncode({
            'action': action,
            'product_id': productId,
            'quantity': quantity,
            if (notes != null) 'notes': notes,
            if (_currentUserId != null) 'created_by': _currentUserId,
          }),
        )
        .timeout(ApiConfig.timeout);
    final body = _decode(res);
    return intOf(body['new_qty']);
  }

  Future<void> setThreshold({required int productId, required int threshold}) async {
    final res = await http
        .post(
          ApiConfig.endpoint(_path),
          headers: _headers,
          body: jsonEncode({'action': 'threshold', 'product_id': productId, 'threshold': threshold}),
        )
        .timeout(ApiConfig.timeout);
    _decode(res);
  }

  Future<void> resolveAlert(int productId) async {
    final res = await http
        .post(
          ApiConfig.endpoint(_path),
          headers: _headers,
          body: jsonEncode({'action': 'resolve_alert', 'product_id': productId}),
        )
        .timeout(ApiConfig.timeout);
    _decode(res);
  }

  /// Soft delete: deactivates the product and zeroes its stock.
  Future<void> deleteAsset(int productId) async {
    final res = await http
        .delete(
          ApiConfig.endpoint(_path),
          headers: _headers,
          body: jsonEncode({'product_id': productId}),
        )
        .timeout(ApiConfig.timeout);
    _decode(res);
  }
}

/// Product master (name, category, price, image…). inventory.php only
/// touches stock_quantity/threshold on existing rows.
class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  static const String _path = 'admin/products.php'; // relative to ApiConfig.baseUrl

  /// Creates a product via `admin/products.php` (multipart, so an [image]
  /// can ride along). The endpoint does not return the new id, so the
  /// opening stock goes in as `stock_quantity` on the same request.
  Future<void> createProduct({
    required String name,
    required String category,
    required double price,
    required String weight,
    required String purity,
    String description = '',
    double? gstRate,
    int stockQuantity = 0,
    bool isActive = true,
    XFile? image,
  }) async {
    final request = http.MultipartRequest('POST', ApiConfig.endpoint(_path))
      ..fields.addAll({
        'name': name,
        'category': category,
        'price': price.toStringAsFixed(2),
        'weight': weight,
        'purity': purity,
        'description': description,
        'is_active': isActive ? '1' : '0',
        'stock_quantity': '$stockQuantity',
        if (gstRate != null) 'gst_rate': gstRate.toString(),
      });
    await _attachImage(request, image);
    await _send(request, 'Create');
  }

  /// Updates a product via `admin/update_product.php` (the list endpoint has
  /// no PUT handler). That endpoint overwrites every column, so all fields
  /// are sent — [existingImage] keeps the current photo unless a new [image]
  /// is uploaded. Stock is left alone here; use [AssetService.adjustStock] so
  /// the change is logged as a movement.
  Future<void> updateProduct({
    required int id,
    required String name,
    required String category,
    required double price,
    required String weight,
    required String purity,
    String description = '',
    double? gstRate,
    required bool isActive,
    String? existingImage,
    XFile? image,
  }) async {
    final request = http.MultipartRequest('POST', ApiConfig.endpoint('admin/update_product.php'))
      ..fields.addAll({
        'id': '$id',
        'name': name,
        'category': category,
        'price': price.toStringAsFixed(2),
        'weight': weight,
        'purity': purity,
        'description': description,
        'is_active': isActive ? '1' : '0',
        if (gstRate != null) 'gst_rate': gstRate.toString(),
        if (existingImage != null && existingImage.isNotEmpty) 'image': existingImage,
      });
    await _attachImage(request, image);
    await _send(request, 'Update');
  }

  Future<void> _attachImage(http.MultipartRequest request, XFile? image) async {
    if (image == null) return;
    // fromBytes, not fromPath: on web an XFile path is a blob URL.
    request.files.add(http.MultipartFile.fromBytes('image', await image.readAsBytes(), filename: image.name));
  }

  Future<void> _send(http.MultipartRequest request, String verb) async {
    final res = await http.Response.fromStream(await request.send().timeout(ApiConfig.timeout));
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    if (res.statusCode != 200 || body?['status'] != 'success') {
      throw AssetServiceException(body?['message']?.toString() ?? '$verb failed (${res.statusCode}).');
    }
  }
}