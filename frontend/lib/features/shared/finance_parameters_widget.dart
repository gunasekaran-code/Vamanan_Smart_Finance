import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class FinanceParametersWidget extends StatefulWidget {
  const FinanceParametersWidget({super.key});

  @override
  State<FinanceParametersWidget> createState() => _FinanceParametersWidgetState();
}

class _FinanceParametersWidgetState extends State<FinanceParametersWidget> {
  // Form Controllers initialized with the values from the design
  final TextEditingController _referralCtrl = TextEditingController(text: '2');
  final TextEditingController _durationCtrl = TextEditingController(text: '10');
  final TextEditingController _tdsCtrl = TextEditingController(text: '5');
  final TextEditingController _serviceChargeCtrl = TextEditingController(text: '5');
  final TextEditingController _minInvestmentCtrl = TextEditingController(text: '1000');
  final TextEditingController _minWithdrawalCtrl = TextEditingController(text: '2000');
  final TextEditingController _goldPriceCtrl = TextEditingController(text: '15313.68');
  final TextEditingController _silverPriceCtrl = TextEditingController(text: '300');
  final TextEditingController _goldSilverGstCtrl = TextEditingController(text: '3');
  final TextEditingController _otherGstCtrl = TextEditingController(text: '10');
  final TextEditingController _processingFeeCtrl = TextEditingController(text: '10');

  @override
  void dispose() {
    _referralCtrl.dispose();
    _durationCtrl.dispose();
    _tdsCtrl.dispose();
    _serviceChargeCtrl.dispose();
    _minInvestmentCtrl.dispose();
    _minWithdrawalCtrl.dispose();
    _goldPriceCtrl.dispose();
    _silverPriceCtrl.dispose();
    _goldSilverGstCtrl.dispose();
    _otherGstCtrl.dispose();
    _processingFeeCtrl.dispose();
    super.dispose();
  }

  void _handleSynchronizeProtocol() {
    ToastService.show(
      title: 'Parameters Synchronized', 
      message: 'Global financial parameters have been updated across the platform.', 
      type: ToastType.success
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
          // Responsive Form Grid
          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 700;

              // Helper function to create responsive rows
              Widget buildRow(Widget child1, Widget? child2) {
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      child1,
                      if (child2 != null) ...[
                        const SizedBox(height: 24),
                        child2,
                      ]
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: child1),
                    const SizedBox(width: 24),
                    Expanded(child: child2 ?? const SizedBox.shrink()),
                  ],
                );
              }

              return Column(
                children: [
                  buildRow(
                    _buildNumberField(label: 'REFERRAL COMMISSION (%)', controller: _referralCtrl, prefixIcon: Icons.people_outline),
                    _buildNumberField(label: 'PLAN DURATION (MONTHS)', controller: _durationCtrl, prefixIcon: Icons.calendar_today_outlined),
                  ),
                  const SizedBox(height: 24),
                  
                  buildRow(
                    _buildNumberField(label: 'TDS (%)', controller: _tdsCtrl, prefixIcon: Icons.percent),
                    _buildNumberField(label: 'SERVICE / PROCESSING CHARGES (%)', controller: _serviceChargeCtrl, prefixIcon: Icons.percent),
                  ),
                  const SizedBox(height: 24),

                  buildRow(
                    _buildNumberField(label: 'MINIMUM INVESTMENT (₹)', controller: _minInvestmentCtrl, prefixIcon: Icons.emoji_events_outlined),
                    _buildNumberField(label: 'MINIMUM WITHDRAWAL (₹)', controller: _minWithdrawalCtrl, prefixIcon: Icons.account_balance_wallet_outlined),
                  ),
                  const SizedBox(height: 24),

                  buildRow(
                    _buildNumberField(label: 'GOLD BASE PRICE (₹/G)', controller: _goldPriceCtrl, prefixIcon: Icons.trending_up),
                    _buildNumberField(label: 'SILVER BASE PRICE (₹/G)', controller: _silverPriceCtrl, prefixIcon: Icons.link),
                  ),
                  const SizedBox(height: 24),

                  buildRow(
                    _buildNumberField(label: 'GOLD/SILVER GST (%)', controller: _goldSilverGstCtrl, prefixIcon: Icons.language),
                    _buildNumberField(label: 'OTHER PRODUCTS GST (%)', controller: _otherGstCtrl, prefixIcon: Icons.language),
                  ),
                  const SizedBox(height: 24),

                  buildRow(
                    _buildNumberField(label: 'PROCESSING FEE (₹)', controller: _processingFeeCtrl, prefixIcon: Icons.credit_card_outlined),
                    null, // Empty right column for the last row
                  ),
                ],
              );
            }
          ),
          
          const SizedBox(height: 48),

          // Action Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _handleSynchronizeProtocol,
              icon: const Icon(Icons.shield_outlined, size: 16),
              label: const Text(
                'SYNCHRONIZE PROTOCOL', 
                style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.5)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF1E3A8A).withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for Number Fields ---
  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Color(0xFF94A3B8), // Slate grey
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w900, 
            fontStyle: FontStyle.italic, 
            color: Color(0xFF1E3A8A), // Navy blue text
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, color: const Color(0xFFCBD5E1), size: 18), // Light grey icon
            suffixIcon: const Icon(Icons.unfold_more, color: Color(0xFF94A3B8), size: 18), // Spinner icon
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: const BorderSide(color: AppColors.kBorder)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: const BorderSide(color: AppColors.kBorder)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: const BorderSide(color: Color(0xFF1E3A8A))
            ),
          ),
        ),
      ],
    );
  }
}