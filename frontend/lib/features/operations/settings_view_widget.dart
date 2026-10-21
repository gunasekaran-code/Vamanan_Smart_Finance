import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/tally_integration_model.dart';
import 'package:frontend/services/tally_integration_service.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'tally_state_views.dart';

/// The ten `tally_settings` keys, loaded from `?resource=settings` and written
/// back through `vouchers.php` with `action=save_settings`.
class SettingsViewWidget extends StatefulWidget {
  const SettingsViewWidget({super.key});

  @override
  State<SettingsViewWidget> createState() => _SettingsViewWidgetState();
}

class _SettingsViewWidgetState extends State<SettingsViewWidget> {
  final TallyIntegrationService _service = TallyIntegrationService();

  final TextEditingController _companyNameCtrl = TextEditingController();
  final TextEditingController _connectionAddressCtrl = TextEditingController();
  final TextEditingController _salesAccountCtrl = TextEditingController();
  final TextEditingController _outputCgstCtrl = TextEditingController();
  final TextEditingController _outputSgstCtrl = TextEditingController();
  final TextEditingController _cashbackExpenseCtrl = TextEditingController();
  final TextEditingController _referralCommissionCtrl = TextEditingController();
  final TextEditingController _bankAccountCtrl = TextEditingController();
  final TextEditingController _customersGroupCtrl = TextEditingController();
  final TextEditingController _stockGroupCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _connectionAddressCtrl.dispose();
    _salesAccountCtrl.dispose();
    _outputCgstCtrl.dispose();
    _outputSgstCtrl.dispose();
    _cashbackExpenseCtrl.dispose();
    _referralCommissionCtrl.dispose();
    _bankAccountCtrl.dispose();
    _customersGroupCtrl.dispose();
    _stockGroupCtrl.dispose();
    super.dispose();
  }

  void _fill(TallySettings settings) {
    _companyNameCtrl.text = settings.company;
    _connectionAddressCtrl.text = settings.gateway;
    _salesAccountCtrl.text = settings.salesLedger;
    _outputCgstCtrl.text = settings.cgstLedger;
    _outputSgstCtrl.text = settings.sgstLedger;
    _cashbackExpenseCtrl.text = settings.cashbackLedger;
    _referralCommissionCtrl.text = settings.referralLedger;
    _bankAccountCtrl.text = settings.bankLedger;
    _customersGroupCtrl.text = settings.debtorsGroup;
    _stockGroupCtrl.text = settings.inventoryGroup;
  }

  /// Reads the form back out. Blank ledger fields fall back to the backend's
  /// own defaults so a cleared box can't post an empty ledger name to Tally.
  TallySettings _collect() {
    const defaults = TallySettings();
    String value(TextEditingController ctrl, String fallback) {
      final text = ctrl.text.trim();
      return text.isEmpty ? fallback : text;
    }

    return TallySettings(
      // Blank company is meaningful: "use whatever company is open in Tally".
      company: _companyNameCtrl.text.trim(),
      gateway: value(_connectionAddressCtrl, defaults.gateway),
      salesLedger: value(_salesAccountCtrl, defaults.salesLedger),
      cgstLedger: value(_outputCgstCtrl, defaults.cgstLedger),
      sgstLedger: value(_outputSgstCtrl, defaults.sgstLedger),
      cashbackLedger: value(_cashbackExpenseCtrl, defaults.cashbackLedger),
      referralLedger: value(_referralCommissionCtrl, defaults.referralLedger),
      bankLedger: value(_bankAccountCtrl, defaults.bankLedger),
      debtorsGroup: value(_customersGroupCtrl, defaults.debtorsGroup),
      inventoryGroup: value(_stockGroupCtrl, defaults.inventoryGroup),
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final settings = await _service.fetchSettings();
      if (!mounted) return;
      _fill(settings);
    } on TallyIntegrationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      // The save returns the stored row, so the form reflects exactly what
      // the ledgers, exports and syncs will now use.
      final saved = await _service.saveSettings(_collect());
      if (!mounted) return;
      _fill(saved);
      ToastService.show(
        title: 'Settings Saved',
        message: 'Tally integration settings have been updated successfully.',
        type: ToastType.success,
      );
    } on TallyIntegrationException catch (e) {
      _toastError(e.message);
    } catch (e) {
      _toastError('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toastError(String message) {
    if (!mounted) return;
    ToastService.show(
      title: 'Could Not Save',
      message: message,
      type: ToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const TallyLoadingCard(label: 'LOADING INTEGRATION SETTINGS');
    }
    if (_error != null) {
      return TallyErrorCard(message: _error!, onRetry: _load);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Header ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kTallyNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: kTallyAmber, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'TALLY ERP PRIME — INTEGRATION SETTINGS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: kTallyNavy,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Reload saved settings',
                onPressed: _isSaving ? null : _load,
                icon: const Icon(Icons.refresh, size: 18, color: kTallyGold),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // --- Form Fields ---
          _buildSettingsField(
            label: 'COMPANY NAME IN TALLY',
            controller: _companyNameCtrl,
            helperText:
                'Leave blank to use whatever company is currently open in Tally',
          ),
          _buildSettingsField(
            label: 'TALLY CONNECTION ADDRESS',
            controller: _connectionAddressCtrl,
            helperText: 'The URL where Tally listens (default: http://localhost:9000)',
          ),
          _buildSettingsField(
            label: 'SALES ACCOUNT NAME',
            controller: _salesAccountCtrl,
            helperText: 'Where sales income is posted in Tally',
          ),
          _buildSettingsField(
            label: 'OUTPUT CGST ACCOUNT',
            controller: _outputCgstCtrl,
            helperText: 'Ledger for CGST collected on sales (intra-state)',
          ),
          _buildSettingsField(
            label: 'OUTPUT SGST ACCOUNT',
            controller: _outputSgstCtrl,
            helperText: 'Ledger for SGST collected on sales (intra-state)',
          ),
          _buildSettingsField(
            label: 'CASHBACK EXPENSE ACCOUNT',
            controller: _cashbackExpenseCtrl,
            helperText: 'Where cashback payouts are recorded',
          ),
          _buildSettingsField(
            label: 'REFERRAL COMMISSION ACCOUNT',
            controller: _referralCommissionCtrl,
            helperText: 'Where referral payouts are recorded',
          ),
          _buildSettingsField(
            label: 'BANK / CASH ACCOUNT',
            controller: _bankAccountCtrl,
            helperText: 'Your main money account in Tally',
          ),
          _buildSettingsField(
            label: 'CUSTOMERS GROUP',
            controller: _customersGroupCtrl,
            helperText:
                'Group under which customer accounts are created (Sundry Debtors)',
          ),
          _buildSettingsField(
            label: 'STOCK / INVENTORY GROUP',
            controller: _stockGroupCtrl,
            helperText: 'Group for your gold / product stock',
          ),

          const SizedBox(height: 16),

          // --- Save Button ---
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline, size: 16),
              label: Text(
                _isSaving ? 'SAVING…' : 'SAVE SETTINGS',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kTallyNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable Input Field Builder ---
  Widget _buildSettingsField({
    required String label,
    required TextEditingController controller,
    required String helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: kTallyMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: !_isSaving,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: kTallyNavy,
            ),
            decoration: InputDecoration(
              fillColor: kTallyTint,
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          const SizedBox(height: 6),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: kTallyMuted.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
