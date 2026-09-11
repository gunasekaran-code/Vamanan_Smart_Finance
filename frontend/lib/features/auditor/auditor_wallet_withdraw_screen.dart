import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// --- Dummy Data Model ---
class WithdrawalItem {
  final String id;
  final double amount;
  final String bank;
  final String status;
  final String date;

  WithdrawalItem({
    required this.id,
    required this.amount,
    required this.bank,
    required this.status,
    required this.date,
  });
}

class AuditorWalletWithdrawScreen extends StatefulWidget {
  const AuditorWalletWithdrawScreen({super.key});

  @override
  State<AuditorWalletWithdrawScreen> createState() => _AuditorWalletWithdrawScreenState();
}

class _AuditorWalletWithdrawScreenState extends State<AuditorWalletWithdrawScreen> {
  // Form Controllers
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _accNumCtrl = TextEditingController();
  final TextEditingController _ifscCtrl = TextEditingController();

  // Explicitly leaving this empty to match the "NO WITHDRAWALS YET" empty state in the image.
  // Add items here to see the table populate.
  final List<WithdrawalItem> _withdrawals = []; 

  // Exact Colors from your design
  final Color _navyBlue = const Color(0xFF1B233A);
  final Color _slateText = const Color(0xFF94A3B8);
  final Color _lightBg = const Color(0xFFF8FAFC);
  final Color _lightBorder = const Color(0xFFF1F5F9);

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNumCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  // --- ACTIONS ---
  Future<void> _handleWithdrawRequest() async {
    if (_amountCtrl.text.isEmpty || _bankNameCtrl.text.isEmpty || _accNumCtrl.text.isEmpty || _ifscCtrl.text.isEmpty) {
      ToastService.show(
        title: 'Validation Error',
        message: 'Please fill in all bank details and the withdrawal amount.',
        type: ToastType.warning,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Confirm Withdrawal',
      message: 'Are you sure you want to request a withdrawal of ₹${_amountCtrl.text} to ${_bankNameCtrl.text}?',
      confirmLabel: 'Request Withdrawal',
      confirmButtonColor: _navyBlue,
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Withdrawal Requested',
        message: 'Your request has been submitted and is pending review.',
        type: ToastType.success,
      );
      
      // Clear form after submission
      setState(() {
        _amountCtrl.clear();
        _bankNameCtrl.clear();
        _accNumCtrl.clear();
        _ifscCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom layout requires no default header
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Perfect for mobile & tablet constraints
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. MAIN WITHDRAWAL FORM CARD
                _buildWithdrawFormCard(),
                const SizedBox(height: 24),

                // 2. GOOD TO KNOW (NAVY CARD)
                _buildGoodToKnowCard(),
                const SizedBox(height: 24),

                // 3. SYSTEM STATUS CARD (GOLD CARD)
                _buildSystemStatusCard(),
                const SizedBox(height: 24),

                // 4. WITHDRAWAL HISTORY TABLE
                _buildWithdrawalHistoryTable(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 1. WITHDRAWAL FORM CARD
  // ==========================================================================
  Widget _buildWithdrawFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Faint Watermark (Bank Icon)
          Positioned(
            top: 40,
            child: Icon(
              Icons.account_balance,
              size: 160,
              color: const Color(0xFFF1F5F9).withOpacity(0.5), // Very faint
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                // Available Balance Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.goldBadgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.goldBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.account_balance_wallet_outlined, color: AppColors.goldColor, size: 14),
                      SizedBox(width: 8),
                      Text(
                        'AVAILABLE BALANCE: ₹0',
                        style: TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Titles
                Text(
                  'WITHDRAW MONEY',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _navyBlue, fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0),
                ),
                const SizedBox(height: 8),
                Text(
                  'ENTER YOUR BANK DETAILS TO RECEIVE YOUR MONEY',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0, height: 1.5),
                ),
                const SizedBox(height: 40),

                // Form Fields
                _buildInputField('AMOUNT (₹)', '0.00', _amountCtrl, isNumber: true, suffixIcon: Icons.unfold_more),
                _buildInputField('BANK NAME', 'Bank Name', _bankNameCtrl),
                _buildInputField('ACCOUNT NUMBER', 'Account Number', _accNumCtrl, isNumber: true),
                _buildInputField('IFSC CODE', 'IFSC CODE', _ifscCtrl),
                
                const SizedBox(height: 16),

                // Request Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleWithdrawRequest,
                    icon: const Icon(Icons.send_outlined, size: 16, color: AppColors.goldColor),
                    label: const Text('REQUEST WITHDRAWAL', style: TextStyle(color: AppColors.goldColor, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navyBlue,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 10,
                      shadowColor: _navyBlue.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, {bool isNumber = false, IconData? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            style: TextStyle(color: _navyBlue, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              filled: true,
              fillColor: _lightBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.kPrimary, width: 2)),
              suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: _navyBlue, size: 24) : null,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. GOOD TO KNOW CARD
  // ==========================================================================
  Widget _buildGoodToKnowCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _navyBlue,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: _navyBlue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, color: AppColors.goldColor, size: 20),
              SizedBox(width: 12),
              Text('GOOD TO KNOW', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          _buildBulletPoint('All withdrawals are reviewed for your security.'),
          _buildBulletPoint('Processing time: 2-24 business hours.'),
          _buildBulletPoint('Limits may apply based on your KYC status.'),
          _buildBulletPoint('Please double-check your bank details before submitting.', isLast: true),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(Icons.circle, color: AppColors.goldColor, size: 6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: 0.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. SYSTEM STATUS CARD
  // ==========================================================================
  Widget _buildSystemStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.goldBadgeBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.goldBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.show_chart_rounded, color: AppColors.goldColor, size: 20),
              SizedBox(width: 12),
              Text('STATUS', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.goldColor, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5, height: 1.5),
              children: [
                const TextSpan(text: 'System status: '),
                TextSpan(text: 'Online. ', style: TextStyle(color: Colors.green.shade600)), // Pop of green for online
                const TextSpan(text: 'Large transfers above ₹50,000 may take a little longer to verify.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 4. WITHDRAWAL HISTORY TABLE
  // ==========================================================================
  Widget _buildWithdrawalHistoryTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.history, color: AppColors.goldColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WITHDRAWAL HISTORY', style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text('YOUR PAST WITHDRAWALS', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 2, color: Color(0xFFF1F5F9)),
          
          // Scrollable Data Table Wrapper
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              // Fixed table width (not just a minWidth) so this doesn't hand an
              // unbounded max-width down to the Column below, which made layout
              // thrash every frame and left the page blank.
              width: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width - 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                    child: Row(
                      children: [
                        _buildHeaderCell('REQUEST\nID', width: 100),
                        _buildHeaderCell('AMOUNT', width: 120),
                        _buildHeaderCell('BANK', width: 150),
                        _buildHeaderCell('STATUS', width: 100),
                        _buildHeaderCell('DATE', width: 100),
                      ],
                    ),
                  ),
                  
                  // Body (Empty State or Data Rows)
                  if (_withdrawals.isEmpty)
                    _buildEmptyState()
                  else
                    ..._withdrawals.map((item) => _buildDataRow(item)).toList(),
                    
                  const SizedBox(height: 24), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header Cell Helper
  Widget _buildHeaderCell(String title, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10, color: Color(0xFF94A3B8), letterSpacing: 1.0),
      ),
    );
  }

  // Data Row Helper
  Widget _buildDataRow(WithdrawalItem item) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Row(
            children: [
              SizedBox(width: 100, child: Text(item.id, style: _dataStyle(color: _navyBlue))),
              SizedBox(width: 120, child: Text('₹${item.amount.toStringAsFixed(2)}', style: _dataStyle(color: _navyBlue, size: 14))),
              SizedBox(width: 150, child: Text(item.bank, style: _dataStyle(color: _slateText))),
              SizedBox(width: 100, child: _buildStatusBadge(item.status)),
              SizedBox(width: 100, child: Text(item.date, style: _dataStyle(color: _slateText, size: 10))),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _dataStyle({Color color = AppColors.kTextDark, double size = 12}) {
    return TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: size, color: color);
  }

  // Status Badge Helper
  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.goldBadgeBg;
    Color text = AppColors.goldColor;

    if (status == 'COMPLETED') {
      bg = const Color(0xFFF0FDF4); text = const Color(0xFF16A34A);
    } else if (status == 'PENDING') {
      bg = const Color(0xFFFFFBEB); text = AppColors.goldColor;
    } else if (status == 'REJECTED') {
      bg = const Color(0xFFFEF2F2); text = const Color(0xFFDC2626);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(
          status,
          style: TextStyle(color: text, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 9, letterSpacing: 0.5),
        ),
      ),
    );
  }

  // Empty State Helper matching the screenshot
  Widget _buildEmptyState() {
    return SizedBox(
      width: double.infinity,
      height: 200, 
      child: Center(
        child: Text(
          'NO WITHDRAWALS YET',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: const Color(0xFF94A3B8).withOpacity(0.8),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}