import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/models/offer_model.dart';

class OfferService {
  OfferService._();
  static final OfferService instance = OfferService._();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<AppOffer>> fetchOffers() async {
    final res = await http
        .get(ApiConfig.endpoint(OfferEndpoints.offers), headers: _headers)
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to load offers (${res.statusCode})');
    }
    final List data = body['data'] ?? [];
    return data.map((e) => AppOffer.fromJson(e)).toList();
  }

  Future<void> createOffer({
    required String title,
    required String details,
    required String category,
    required String colorName,
    String? endsAt, // 'YYYY-MM-DD' or null
    String? startsAt,
    String? image,
  }) async {
    final res = await http
        .post(
          ApiConfig.endpoint(OfferEndpoints.offers),
          headers: _headers,
          body: jsonEncode({
            'action': 'create',
            'title': title,
            'message': details,
            'badge': category,
            'color': colorName,
            'starts_at': startsAt,
            'ends_at': endsAt,
            'image': image ?? '',
          }),
        )
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to publish offer (${res.statusCode})');
    }
  }

  Future<void> toggleOffer(String id) async {
    final res = await http
        .post(
          ApiConfig.endpoint(OfferEndpoints.offers),
          headers: _headers,
          body: jsonEncode({'action': 'toggle', 'id': id}),
        )
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to update offer (${res.statusCode})');
    }
  }

  Future<void> deleteOffer(String id) async {
    final res = await http
        .post(
          ApiConfig.endpoint(OfferEndpoints.offers),
          headers: _headers,
          body: jsonEncode({'action': 'delete', 'id': id}),
        )
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to delete offer (${res.statusCode})');
    }
  }
}