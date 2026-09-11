import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'asset_inventory_screen.dart'; // To access the Asset class

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

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _purityController;
  late TextEditingController _specificationController;
  late TextEditingController _valuationController;
  late TextEditingController _gstController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;

  String _selectedCategory = "VEHICLES (2WHEELER/4WHEELER)";
  final List<String> _categories = [
    "VEHICLES (2WHEELER/4WHEELER)",
    "GOLD",
    "SILVER",
    "SCHOOL FEES",
    "ELECTRONICS"
  ];

  @override
  void initState() {
    super.initState();
    _isPreciousMetal = widget.asset?.isPreciousMetal ?? false;
    _isActive = widget.asset?.isActive ?? true;

    _nameController = TextEditingController(text: widget.asset?.name ?? '');
    _weightController = TextEditingController();
    _purityController = TextEditingController(text: _isPreciousMetal ? '24K — 99.9% PURE GOLD' : '');
    _specificationController = TextEditingController(text: widget.asset?.name ?? '');
    _valuationController = TextEditingController(text: widget.asset?.valuation.toStringAsFixed(2) ?? '');
    _gstController = TextEditingController(text: '28.00'); // Default Mock
    _quantityController = TextEditingController(text: widget.asset?.stock.toString() ?? '0');
    _descriptionController = TextEditingController(text: widget.asset?.name ?? '');

    if (isEditMode && _categories.contains(widget.asset!.category.replaceAll('\n', ' '))) {
       _selectedCategory = widget.asset!.category.replaceAll('\n', ' ');
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

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final updatedAsset = Asset(
        id: isEditMode ? widget.asset!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        metric: _isPreciousMetal ? 'PM • ${_nameController.text}' : 'OG • ${_nameController.text}',
        valuation: double.tryParse(_valuationController.text) ?? 0.0,
        stock: int.tryParse(_quantityController.text) ?? 0,
        isActive: _isActive,
        isPreciousMetal: _isPreciousMetal,
      );
      Navigator.pop(context, updatedAsset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton( // Back button in header
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.kTextMuted),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode ? 'EDIT ASSET' : 'PROVISION NEW ASSET',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
            ),
            Text(
              _isPreciousMetal ? 'GOLD, SILVER & JEWELLERY INVENTORY' : 'ELECTRONICS, ACCESSORIES & GENERAL PRODUCTS',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tab Toggle Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPreciousMetal = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isPreciousMetal ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                        decoration: BoxDecoration(
                          color: !_isPreciousMetal ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
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

              // Dynamic Fields based on Type
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
                  Expanded(child: _buildInputField(label: 'GST RATE (%)', controller: _gstController, isNumber: true, suffixText: '%', subLabel: 'BLANK = USE CATEGORY DEFAULT')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField(label: 'QUANTITY (STOCK)', controller: _quantityController, isNumber: true, subLabel: 'UNITS AVAILABLE IN STOCK')),
                ],
              ),

              // Image Upload box
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PRODUCT IMAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.kBorder, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, color: AppColors.kTextMuted, size: 20),
                        SizedBox(width: 8),
                        Text('CLICK TO UPLOAD IMAGE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Active Toggle
              Row(
                children: [
                  Switch(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFFD97706), // Orange active track
                  ),
                  const SizedBox(width: 8),
                  Text(_isActive ? 'ACTIVE (ACTIVE)' : 'INACTIVE', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              _buildInputField(label: 'DESCRIPTION', controller: _descriptionController, maxLines: 3, hintText: 'Optional product description...'),
              const SizedBox(height: 32),

              // Bottom Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppColors.kBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(Icons.bolt, size: 18),
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

  // Helper Widget: Input Field customized for Asset Forms
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool isNumber = false,
    String? prefixText,
    String? suffixText,
    String? subLabel,
    int maxLines = 1,
  }) {
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
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.normal, fontStyle: FontStyle.normal),
              prefixText: prefixText,
              prefixStyle: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold),
              suffixText: suffixText,
              suffixStyle: const TextStyle(color: AppColors.kTextMuted),
              suffixIcon: isNumber && maxLines == 1 ? const Icon(Icons.unfold_more, color: AppColors.kTextMuted, size: 18) : null,
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
          ]
        ],
      ),
    );
  }

  // Helper Widget: Dropdown Field customized for Asset Forms
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
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