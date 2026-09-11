import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart'; // Make sure this path is correct for your toast service

class SettingsViewWidget extends StatefulWidget {
  const SettingsViewWidget({super.key});

  @override
  State<SettingsViewWidget> createState() => _SettingsViewWidgetState();
}

class _SettingsViewWidgetState extends State<SettingsViewWidget> {
  // Form Controllers initialized with the default values shown in the design
  final TextEditingController _companyNameCtrl = TextEditingController();
  final TextEditingController _connectionAddressCtrl = TextEditingController(text: 'http://localhost:9000');
  final TextEditingController _salesAccountCtrl = TextEditingController(text: 'Sales Account');
  final TextEditingController _outputCgstCtrl = TextEditingController(text: 'Output CGST');
  final TextEditingController _outputSgstCtrl = TextEditingController(text: 'Output SGST');
  final TextEditingController _cashbackExpenseCtrl = TextEditingController(text: 'Cashback Expense');
  final TextEditingController _referralCommissionCtrl = TextEditingController(text: 'Referral Commission');
  final TextEditingController _bankAccountCtrl = TextEditingController(text: 'Bank Account');
  final TextEditingController _customersGroupCtrl = TextEditingController(text: 'Sundry Debtors');
  final TextEditingController _stockGroupCtrl = TextEditingController(text: 'Gold Stock');

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

  void _handleSave() {
    ToastService.show(
      title: 'Settings Saved',
      message: 'Tally integration settings have been updated successfully.',
      type: ToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFF1E3A8A), // Navy Blue
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Color(0xFFFBBF24), size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'TALLY ERP PRIME — INTEGRATION SETTINGS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E3A8A),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // --- Form Fields ---
          _buildSettingsField(
            label: 'COMPANY NAME IN TALLY',
            controller: _companyNameCtrl,
            helperText: 'Leave blank to use whatever company is currently open in Tally',
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
            helperText: 'Group under which customer accounts are created (Sundry Debtors)',
          ),
          _buildSettingsField(
            label: 'STOCK / INVENTORY GROUP',
            controller: _stockGroupCtrl,
            helperText: 'Group for your gold / product stock',
          ),
          
          const SizedBox(height: 16),

          // --- Save Button ---
          Align(
            alignment: Alignment.centerLeft, // Left aligned as per design
            child: ElevatedButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text(
                'SAVE SETTINGS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
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
              color: Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF1E3A8A), // Navy text for input
            ),
            decoration: InputDecoration(
              fillColor: const Color(0xFFF8FAFC),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF94A3B8).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}