import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/tally_integration_model.dart';
import 'tally_state_views.dart';

/// Create / edit form for a managed voucher. Returns the [TallyVoucherDraft]
/// to send, or null if the user cancelled.
class VoucherFormDialog extends StatefulWidget {
  final TallyVoucher? existing;

  const VoucherFormDialog({super.key, this.existing});

  static Future<TallyVoucherDraft?> show(
    BuildContext context, {
    TallyVoucher? existing,
  }) {
    return showDialog<TallyVoucherDraft>(
      context: context,
      builder: (_) => VoucherFormDialog(existing: existing),
    );
  }

  @override
  State<VoucherFormDialog> createState() => _VoucherFormDialogState();
}

class _VoucherFormDialogState extends State<VoucherFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _voucherNoCtrl;
  late final TextEditingController _partyCtrl;
  late final TextEditingController _debitCtrl;
  late final TextEditingController _creditCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _narrationCtrl;
  late final TextEditingController _referenceCtrl;

  late String _voucherType;
  late DateTime _voucherDate;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _voucherNoCtrl = TextEditingController(text: v?.voucherNo ?? '');
    _partyCtrl = TextEditingController(text: v?.partyLedger ?? '');
    _debitCtrl = TextEditingController(text: v?.debitLedger ?? '');
    _creditCtrl = TextEditingController(text: v?.creditLedger ?? '');
    _amountCtrl = TextEditingController(
      text: v == null || v.amount == 0 ? '' : v.amount.toStringAsFixed(2),
    );
    _narrationCtrl = TextEditingController(text: v?.narration ?? '');
    _referenceCtrl = TextEditingController(text: v?.reference ?? '');
    _voucherType = v?.voucherType ?? 'Journal';
    _voucherDate = DateTime.tryParse(v?.voucherDate ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    _voucherNoCtrl.dispose();
    _partyCtrl.dispose();
    _debitCtrl.dispose();
    _creditCtrl.dispose();
    _amountCtrl.dispose();
    _narrationCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  String _wireDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _voucherDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _voucherDate = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      TallyVoucherDraft(
        id: widget.existing?.id,
        voucherNo: _voucherNoCtrl.text.trim(),
        voucherType: _voucherType,
        voucherDate: _wireDate(_voucherDate),
        partyLedger: _partyCtrl.text.trim(),
        debitLedger: _debitCtrl.text.trim(),
        creditLedger: _creditCtrl.text.trim(),
        amount: double.tryParse(_amountCtrl.text.trim()) ?? 0,
        narration: _narrationCtrl.text.trim(),
        reference: _referenceCtrl.text.trim(),
        // Vouchers made here are hand-entered; the generator owns the others.
        source: widget.existing?.source ?? 'manual',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'EDIT VOUCHER' : 'NEW VOUCHER',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: kTallyNavy,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20, color: kTallyMuted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.kBorder),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField(
                        label: 'VOUCHER NO',
                        controller: _voucherNoCtrl,
                        hint: 'Leave blank to auto-number (JV-…)',
                      ),
                      _buildTypeAndDate(),
                      _buildField(
                        label: 'PARTY LEDGER',
                        controller: _partyCtrl,
                        hint: 'Customer or party name as it appears in Tally',
                      ),
                      _buildField(label: 'DEBIT LEDGER', controller: _debitCtrl),
                      _buildField(label: 'CREDIT LEDGER', controller: _creditCtrl),
                      _buildField(
                        label: 'AMOUNT',
                        controller: _amountCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final amount = double.tryParse(value?.trim() ?? '');
                          if (amount == null) return 'Enter a valid amount';
                          if (amount <= 0) return 'Amount must be greater than zero';
                          return null;
                        },
                      ),
                      _buildField(label: 'REFERENCE', controller: _referenceCtrl),
                      _buildField(
                        label: 'NARRATION',
                        controller: _narrationCtrl,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: AppColors.kBorder),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCEL',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                              color: kTallySlate,
                              letterSpacing: 1)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(_isEdit ? 'SAVE CHANGES' : 'CREATE VOUCHER',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                              letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTallyNavy,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeAndDate() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('VOUCHER TYPE'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: kTallyTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _voucherType,
                      isExpanded: true,
                      icon: const Icon(Icons.unfold_more, size: 16, color: kTallyNavy),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kTallyNavy,
                      ),
                      items: kTallyVoucherTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _voucherType = v ?? _voucherType),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('VOUCHER DATE'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                    decoration: BoxDecoration(
                      color: kTallyTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    child: Text(_wireDate(_voucherDate),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: kTallyNavy)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: kTallyMuted,
          letterSpacing: 1,
        ),
      );

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: kTallyNavy,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: kTallyMuted,
              ),
              fillColor: kTallyTint,
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kTallyNavy),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
