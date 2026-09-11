import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class WalletAdjustmentScreen extends StatefulWidget {
  const WalletAdjustmentScreen({super.key});

  @override
  State<WalletAdjustmentScreen> createState() => _WalletAdjustmentScreenState();
}

class _WalletAdjustmentScreenState extends State<WalletAdjustmentScreen> {
  // Form State
  String _selectedCustomer = 'TAMILARASI.N [TAMILARASI8345@GMAIL.COM]';
  String _selectedDirection = 'INJECT CAPITAL (CREDIT +)';
  final TextEditingController _amountController = TextEditingController(text: '0.00');
  final TextEditingController _rationaleController = TextEditingController();

  final List<String> _customers = [
    'TAMILARASI.N [TAMILARASI8345@GMAIL.COM]',
    'GUNA SEKARAN V. [GUNA@GMAIL.COM]',
    'SARANYA VENKAT [SARANYA@GMAIL.COM]',
  ];

  final List<String> _directions = [
    'INJECT CAPITAL (CREDIT +)',
    'DEDUCT CAPITAL (DEBIT -)',
  ];

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message: "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(title: 'Success', message: 'Monthly yield processed successfully.', type: ToastType.success);
    }
  }

  void _handlePayout() {
    // Perform validation and action
    if (_rationaleController.text.isEmpty) {
      ToastService.show(title: 'Validation Error', message: 'Please specify an authorization rationale.', type: ToastType.error);
      return;
    }

    ToastService.show(title: 'Protocol Executed', message: 'Wallet adjustment has been successfully processed.', type: ToastType.success);
    
    // Clear form after success
    setState(() {
      _amountController.text = '0.00';
      _rationaleController.clear();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rationaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Global Search Bar ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- 2. Process Monthly Yield Button ---
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('PROCESS MONTHLY YIELD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Main Protocol Card ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.account_balance_wallet, color: Color(0xFFFBBF24), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CAPITAL CORRECTION PROTOCOL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                              const SizedBox(height: 4),
                              Text('MANUAL INTERVENTION LAYER FOR INVESTOR WALLET ADJUSTMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Dropdowns (Responsive)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;
                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDropdownField('TARGET CUSTOMER', _selectedCustomer, _customers, (val) => setState(() => _selectedCustomer = val!)),
                              const SizedBox(height: 16),
                              _buildDropdownField('CORRECTION DIRECTION', _selectedDirection, _directions, (val) => setState(() => _selectedDirection = val!)),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: _buildDropdownField('TARGET CUSTOMER', _selectedCustomer, _customers, (val) => setState(() => _selectedCustomer = val!))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDropdownField('CORRECTION DIRECTION', _selectedDirection, _directions, (val) => setState(() => _selectedDirection = val!))),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 24),

                    // Stats Box 1 (Gold/Amber Theme)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB), // Light amber tint
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildStatColumn('MONTHLY PAYOUT', '₹0', '• 10% MONTHLY INSTALLMENT', const Color(0xFFD97706))),
                          Expanded(child: _buildStatColumn('REMAINING CAPITAL', '₹0', '0% PROGRESS', const Color(0xFF3B82F6))),
                          Expanded(child: _buildStatColumn('TOTAL INVESTED', '₹0', '22K GOLD ASSET', const Color(0xFFD97706))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Box 2 (Grey/Blue Theme)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.kBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildStatColumn('WALLET BALANCE', '₹0', null, const Color(0xFFD97706))),
                          Expanded(child: _buildStatColumn('TOTAL EARNED', '₹0', null, const Color(0xFF94A3B8))),
                          Expanded(child: _buildStatColumn('MONTHS PROGRESS', '0/10', null, const Color(0xFF3B82F6))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Injection Quantity Input
                    _buildInputField(
                      label: 'INJECTION QUANTITY (₹)',
                      controller: _amountController,
                      prefixText: '₹  ',
                      isNumber: true,
                    ),
                    const SizedBox(height: 24),

                    // Rationale Input
                    _buildInputField(
                      label: 'AUTHORIZATION RATIONALE',
                      controller: _rationaleController,
                      hintText: 'Specify the precise reason for this manual intervention...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    // Pay Out Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handlePayout,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('PAY OUT', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 14, letterSpacing: 2)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
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

  // --- Helper Widgets ---

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(Icons.unfold_more, color: Color(0xFF1E3A8A), size: 18),
          isExpanded: true, // Prevents overflow on long text
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item, 
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, String? subLabel, Color subLabelColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
        if (subLabel != null) ...[
          const SizedBox(height: 6),
          Text(subLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: subLabelColor, letterSpacing: 0.5), textAlign: TextAlign.center),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? prefixText,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: isNumber ? 24 : 14, 
            fontWeight: FontWeight.w900, 
            fontStyle: FontStyle.italic, 
            color: isNumber ? const Color(0xFF94A3B8) : const Color(0xFF1E3A8A)
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.normal, fontStyle: FontStyle.normal, fontSize: 13),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 24),
            suffixIcon: isNumber ? const Icon(Icons.unfold_more, color: AppColors.kTextMuted) : null,
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
        ),
      ],
    );
  }
}