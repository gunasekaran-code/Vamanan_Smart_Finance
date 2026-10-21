import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/product_thumbnail.dart';
import '../../models/asset_model.dart';
import '../../services/asset_service.dart';

class AssetFormScreen extends StatefulWidget {
  final Asset? asset;
  const AssetFormScreen({super.key, this.asset});

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get isEditMode => widget.asset != null;
  bool _isPreciousMetal = false;
  bool _isActive = true;
  bool _saving = false;

  /// Newly picked photo (uploaded on save) and its bytes for the preview.
  XFile? _pickedImage;
  Uint8List? _pickedBytes;

  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _purityController;
  late TextEditingController _specificationController;
  late TextEditingController _valuationController;
  late TextEditingController _gstController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;

  String _selectedCategory = "VEHICLES (2WHEELER/4WHEELER)";
  final List<String> _categories = ["VEHICLES (2WHEELER/4WHEELER)", "GOLD", "SILVER", "SCHOOL FEES", "ELECTRONICS"];

  /// Stored weight is meaningful only for gold/silver; general products keep '0'.
  static String _cleanWeight(String? w) => (w == null || w.trim().isEmpty || double.tryParse(w) == 0) ? '' : w.trim();

  @override
  void initState() {
    super.initState();
    _isPreciousMetal = widget.asset?.isPreciousMetal ?? false;
    _isActive = widget.asset?.isActive ?? true;

    final a = widget.asset;
    // The `purity` column holds the karat for gold/silver and the
    // specification text for general products.
    _nameController = TextEditingController(text: a?.name ?? '');
    _weightController = TextEditingController(text: _cleanWeight(a?.weight));
    _purityController = TextEditingController(
        text: a == null ? '24K — 99.9% PURE GOLD' : (_isPreciousMetal ? a.purity : ''));
    _specificationController = TextEditingController(text: a != null && !_isPreciousMetal ? a.purity : '');
    _valuationController = TextEditingController(text: a?.valuation.toStringAsFixed(2) ?? '');
    _gstController = TextEditingController(text: a?.gstRate?.toStringAsFixed(2) ?? '');
    _quantityController = TextEditingController(text: a?.stock.toString() ?? '0');
    _descriptionController = TextEditingController(text: a?.description ?? '');

    // Keep the product's stored category (and its casing) — replace the
    // matching preset, or add it when it is not one of the presets.
    if (a != null && a.category.trim().isNotEmpty) {
      final i = _categories.indexWhere((c) => c.toLowerCase() == a.category.toLowerCase());
      if (i >= 0) {
        _categories[i] = a.category;
      } else {
        _categories.add(a.category);
      }
      _selectedCategory = a.category;
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImage = file;
        _pickedBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open image: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _purityController.dispose();
    _specificationController.dispose();
    _valuationController.dispose();
    _gstController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final name = _nameController.text.trim();
    final valuation = double.tryParse(_valuationController.text) ?? 0.0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final weight = _isPreciousMetal ? _weightController.text.trim() : '0';
    final purity = (_isPreciousMetal ? _purityController.text : _specificationController.text).trim();
    final description = _descriptionController.text.trim();
    final gstRate = double.tryParse(_gstController.text.trim());

    try {
      if (isEditMode) {
        final id = widget.asset!.id;
        await ProductService.instance.updateProduct(
          id: id,
          name: name,
          category: _selectedCategory,
          price: valuation,
          weight: weight,
          purity: purity,
          description: description,
          gstRate: gstRate,
          isActive: _isActive,
          existingImage: widget.asset!.image,
          image: _pickedImage,
        );
        if (quantity != widget.asset!.stock) {
          await AssetService.instance.adjustStock(productId: id, action: 'set', quantity: quantity, notes: 'Edited via asset form');
        }
      } else {
        await ProductService.instance.createProduct(
          name: name,
          category: _selectedCategory,
          price: valuation,
          weight: weight,
          purity: purity,
          description: description,
          gstRate: gstRate,
          stockQuantity: quantity,
          isActive: _isActive,
          image: _pickedImage,
        );
      }
      if (!mounted) return;
      _close(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// Leaves the form. It opens inside the app shell (a child of
  /// `/asset-inventory`), so pop back to the list — or go there directly
  /// when there is nothing to pop, e.g. after a browser refresh.
  void _close([bool? saved]) {
    if (context.canPop()) {
      context.pop(saved);
    } else {
      context.go('/asset-inventory');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditMode ? 'EDIT ASSET' : 'PROVISION NEW ASSET',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
              Text(
                _isPreciousMetal ? 'GOLD, SILVER & JEWELLERY INVENTORY' : 'ELECTRONICS, ACCESSORIES & GENERAL PRODUCTS',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPreciousMetal = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: _isPreciousMetal ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.diamond_outlined, size: 16, color: _isPreciousMetal ? const Color(0xFFFDE68A) : const Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Text('PRECIOUS METAL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: _isPreciousMetal ? const Color(0xFFFDE68A) : const Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPreciousMetal = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: !_isPreciousMetal ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 16, color: !_isPreciousMetal ? const Color(0xFFFDE68A) : const Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Text('GENERAL PRODUCT', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: !_isPreciousMetal ? const Color(0xFFFDE68A) : const Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInputField(
                label: _isPreciousMetal ? 'ASSET NAME *' : 'PRODUCT NAME *',
                controller: _nameController,
                hintText: _isPreciousMetal ? 'e.g. 22K GOLD COIN 1G' : 'Enter product name',
              ),
              if (_isPreciousMetal) ...[
                _buildInputField(label: 'WEIGHT (GRAMS) *', controller: _weightController, hintText: 'e.g. 1', isNumber: true),
                _buildInputField(label: 'PURITY / KARAT', controller: _purityController),
              ] else ...[
                _buildInputField(label: 'SPECIFICATION / MODEL', controller: _specificationController),
              ],
              _buildDropdownField(label: 'CATEGORY', value: _selectedCategory, items: _categories, onChanged: (val) => setState(() => _selectedCategory = val!)),
              _buildInputField(label: 'VALUATION (₹) *', controller: _valuationController, isNumber: true, prefixText: '₹  '),
              Row(
                children: [
                  Expanded(child: _buildInputField(label: 'GST RATE (%)', controller: _gstController, isNumber: true, suffixText: '%', hintText: 'Default', subLabel: 'LEAVE BLANK FOR PLATFORM DEFAULT')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField(label: 'QUANTITY (STOCK)', controller: _quantityController, isNumber: true, subLabel: 'UNITS AVAILABLE IN STOCK')),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRODUCT IMAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
                  const SizedBox(height: 6),
                  if (_pickedBytes != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            height: 180,
                            color: const Color(0xFFF1F5F9),
                            child: Image.memory(_pickedBytes!, fit: BoxFit.contain),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'Discard new image',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close, color: Colors.white, size: 18),
                              onPressed: _saving
                                  ? null
                                  : () => setState(() {
                                        _pickedImage = null;
                                        _pickedBytes = null;
                                      }),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ] else if (widget.asset?.imageUrl != null) ...[
                    ProductThumbnail(
                      url: widget.asset!.imageUrl,
                      width: double.infinity,
                      height: 180,
                      borderRadius: 8,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                  ],
                  InkWell(
                    onTap: _saving ? null : _pickImage,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.kBorder), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: AppColors.kTextMuted, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _pickedImage != null
                                  ? _pickedImage!.name.toUpperCase()
                                  : (widget.asset?.imageUrl != null ? 'CLICK TO CHANGE IMAGE' : 'CLICK TO UPLOAD IMAGE'),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Switch(value: _isActive, onChanged: (val) => setState(() => _isActive = val), activeColor: Colors.white, activeTrackColor: const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text(_isActive ? 'ACTIVE (ACTIVE)' : 'INACTIVE', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 16),
              _buildInputField(label: 'DESCRIPTION', controller: _descriptionController, maxLines: 3, hintText: 'Optional product description...'),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _close(),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppColors.kBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _onSave,
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bolt, size: 18),
                      label: Text(isEditMode ? 'SAVE CHANGES' : 'PROVISION ASSET', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, String? hintText, bool isNumber = false, String? prefixText, String? suffixText, String? subLabel, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
            validator: (v) => (v == null || v.trim().isEmpty) && (label.contains('*')) ? 'Required' : null,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.normal, fontStyle: FontStyle.normal),
              prefixText: prefixText,
              prefixStyle: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold),
              suffixText: suffixText,
              suffixStyle: const TextStyle(color: AppColors.kTextMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5)),
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 4),
            Text(subLabel, style: const TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownField({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : items.first,
            onChanged: onChanged,
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.kTextMuted),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5)),
            ),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          ),
        ],
      ),
    );
  }
}