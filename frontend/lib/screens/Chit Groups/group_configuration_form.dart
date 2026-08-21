import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'chit_groups_screen.dart'; // Adjust path based on project layout

class ChitGroupFormSheet extends StatefulWidget {
  final ChitGroup? group;

  const ChitGroupFormSheet({super.key, this.group});

  @override
  State<ChitGroupFormSheet> createState() => _ChitGroupFormSheetState();
}

class _ChitGroupFormSheetState extends State<ChitGroupFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _valueController;
  late TextEditingController _durationController;
  late TextEditingController _installmentController;
  late TextEditingController _startDateController;
  late TextEditingController _dueDayController;
  late TextEditingController _penaltyController;
  String _status = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameController = TextEditingController(text: g?.name ?? '');
    _valueController = TextEditingController(text: g != null ? g.value.toStringAsFixed(0) : '');
    _durationController = TextEditingController(text: g?.duration.replaceAll(' Months', '') ?? '');
    _installmentController = TextEditingController(text: g != null ? g.installment.toStringAsFixed(0) : '');
    _startDateController = TextEditingController(text: g?.startDate ?? '21/08/2026');
    _dueDayController = TextEditingController(text: '10');
    _penaltyController = TextEditingController(text: '0.00');
    _status = g?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _durationController.dispose();
    _installmentController.dispose();
    _startDateController.dispose();
    _dueDayController.dispose();
    _penaltyController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final updatedGroup = ChitGroup(
        id: widget.group?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        code: widget.group?.code ?? 'CHIT-00${DateTime.now().second}',
        value: double.tryParse(_valueController.text) ?? 0.0,
        installment: double.tryParse(_installmentController.text) ?? 0.0,
        duration: '${_durationController.text.trim()} Months',
        startDate: _startDateController.text.trim(),
        status: _status,
      );
      Navigator.pop(context, updatedGroup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.group != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card matching design
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.slideshow_rounded, color: Colors.blue.shade700, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Chit Group' : 'Group Configuration',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Define chit value, cycle duration and installment plans',
                            style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Input Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  return Column(
                    children: [
                      _buildRow(
                        isWide,
                        _buildTextField(_nameController, 'Chit Group Name', Icons.local_offer_outlined),
                        _buildTextField(_valueController, 'Total Chit Value (Corpus)', Icons.currency_rupee, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        isWide,
                        _buildTextField(_durationController, 'Duration (Months)', Icons.calendar_today_outlined, keyboardType: TextInputType.number),
                        _buildTextField(_installmentController, 'Monthly Installment (₹)', Icons.account_balance_wallet_outlined, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        isWide,
                        _buildTextField(_startDateController, 'Commencement Date', Icons.date_range_outlined),
                        _buildTextField(_dueDayController, 'Fixed Due Day (1-31)', Icons.event_available_outlined, keyboardType: TextInputType.number),
                      ),
                      const SizedBox(height: 12),
                      _buildRow(
                        isWide,
                        _buildTextField(_penaltyController, 'Daily Penalty (₹/Day)', Icons.error_outline, keyboardType: TextInputType.number),
                        _buildDropdownField(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.kBorder),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveForm,
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kSuccess,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Discard', style: TextStyle(color: AppColors.kTextDark, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(bool isWide, Widget first, Widget second) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    }
    return Column(
      children: [
        first,
        const SizedBox(height: 12),
        second,
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (val) => (val == null || val.isEmpty) ? 'Field required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: InputDecoration(
        labelText: 'Operating Status',
        prefixIcon: const Icon(Icons.shield_outlined, size: 20, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      items: const [
        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
        DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _status = val);
      },
    );
  }
}