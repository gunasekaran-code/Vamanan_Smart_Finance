import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class AuditorDashboardScreen extends StatefulWidget {
  const AuditorDashboardScreen({super.key});

  @override
  State<AuditorDashboardScreen> createState() => _AuditorDashboardScreenState();
}

class _AuditorDashboardScreenState extends State<AuditorDashboardScreen> {
  // Theme Color Aliases
  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _slateText = AppColors.kTextMuted;
  final Color _lightBorder = const Color(0xFFF1F5F9);
  final Color _lightBg = const Color(0xFFF8FAFC);

  // Feedback State
  int _feedbackTab = 0; // 0: Write, 1: Team, 2: Submissions
  final _feedbackSubjectCtrl = TextEditingController();
  final _feedbackMsgCtrl = TextEditingController();

  @override
  void dispose() {
    _feedbackSubjectCtrl.dispose();
    _feedbackMsgCtrl.dispose();
    super.dispose();
  }

  // --- ACTIONS & ROUTING ---
  void _routeToBuy() {
    context.push('/auditor-buy');
  }

  void _routeToReferral() {
    context.push('/auditor-referral');
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ToastService.show(
      title: 'Copied',
      message: 'Referral code copied to clipboard.',
      type: ToastType.success,
    );
  }

  void _submitFeedback() {
    if (_feedbackSubjectCtrl.text.isEmpty || _feedbackMsgCtrl.text.isEmpty) {
      ToastService.show(title: 'Error', message: 'Please fill out all fields.', type: ToastType.error);
      return;
    }
    ToastService.show(title: 'Success', message: 'Feedback submitted to the admin team.', type: ToastType.success);
    _feedbackSubjectCtrl.clear();
    _feedbackMsgCtrl.clear();
    setState(() => _feedbackTab = 2);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom Header
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Desktop/Tablet constraint
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER & INVEST NOW BUTTON
                _buildHeader(),
                const SizedBox(height: 24),

                // 2. MAIN NAVY CARD (TOTAL PURCHASE)
                _buildTotalPurchaseCard(),
                const SizedBox(height: 16),

                // 3. VERTICAL STAT CARDS LIST
                _buildVerticalStatsList(),
                const SizedBox(height: 24),

                // 4. INVESTMENT PROGRESS
                _buildInvestmentProgressCard(),
                const SizedBox(height: 24),

                // 5. NETWORK EXPANSION
                _buildNetworkExpansionCard(),
                const SizedBox(height: 24),

                // 6. GROWTH INSIGHTS
                _buildGrowthInsightsCard(),
                const SizedBox(height: 24),

                // 7. IMPORTANT NOTICE (GOLD CARD)
                _buildImportantNoticeCard(),
                const SizedBox(height: 24),

                // 8. WALLET OPERATIONS (EMPTY STATE)
                _buildWalletOperationsCard(),
                const SizedBox(height: 24),

                // 9. FEEDBACK & REMARKS
                _buildFeedbackSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // WIDGETS
  // ==========================================================================

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.circle, color: AppColors.goldColor, size: 8),
                  SizedBox(width: 8),
                  Text('AUDITOR SESSION', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0)),
                ],
              ),
              const SizedBox(height: 8),
              Text('DASHBOARD', style: TextStyle(color: _navyBlue, fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
              const SizedBox(height: 4),
              Text('WELCOME BACK, TEST AUDITOR • UNVERIFIED LEDGER', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _routeToBuy,
          style: ElevatedButton.styleFrom(
            backgroundColor: _navyBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 10,
            shadowColor: _navyBlue.withOpacity(0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('INVEST NOW', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.0)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalPurchaseCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _navyBlue,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: _navyBlue.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, bottom: -20,
            child: Icon(Icons.account_balance_wallet, size: 160, color: Colors.white.withOpacity(0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.trending_up, color: AppColors.goldColor, size: 20),
              ),
              const SizedBox(height: 24),
              const Text('TOTAL PURCHASE (NET)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text('₹0', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
              const SizedBox(height: 8),
              const Text('CASHBACK BASIS: ₹0', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalStatsList() {
    return Column(
      children: [
        _buildListStatCard('DAILY CASHBACK', '₹0', Icons.bolt, AppColors.goldBadgeBg, AppColors.goldColor, subtitle: '0% OF PURCHASE'),
        const SizedBox(height: 12),
        _buildListStatCard('REFERRAL COMMISSIONS', '₹0', Icons.people_outline, AppColors.goldBadgeBg, AppColors.goldColor),
        const SizedBox(height: 12),
        _buildListStatCard('NET YIELD (TOTAL EARNINGS)', '₹0', Icons.monetization_on_outlined, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
        const SizedBox(height: 12),
        _buildListStatCard('WITHDRAWN AMOUNT', '₹0', Icons.arrow_outward, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
        const SizedBox(height: 12),
        _buildListStatCard('AVAILABLE BALANCE', '₹0', Icons.account_balance_wallet_outlined, const Color(0xFFF3E8FF), const Color(0xFF9333EA)),
        const SizedBox(height: 12),
        _buildListStatCard('ASSET INVENTORY', '0', Icons.inventory_2_outlined, const Color(0xFFF1F5F9), _navyBlue, subtitle: 'GRAMS'),
      ],
    );
  }

  Widget _buildListStatCard(String title, String value, IconData icon, Color iconBg, Color iconColor, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: _lightBorder, width: 2)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                ]
              ],
            ),
          ),
          Text(value, style: TextStyle(color: _navyBlue, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildInvestmentProgressCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INVESTMENT PROGRESS', style: TextStyle(color: _navyBlue, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('TRACK YOUR RETURN ON INVESTMENT', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL YIELD LIMIT', style: TextStyle(color: _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              const Text('UP TO 100% ROI', style: TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('₹0 / ₹0', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
          const SizedBox(height: 16),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: 0.0, backgroundColor: const Color(0xFFF1F5F9), color: AppColors.goldColor, minHeight: 10),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(child: _buildProgressStat('YIELD CAP', '₹0', Icons.lock_outline, _slateText)),
              Expanded(child: _buildProgressStat('EARNED', '₹0', Icons.monetization_on_outlined, AppColors.goldColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildProgressStat('REMAINING', '₹0', Icons.pending_actions, const Color(0xFF3B82F6))),
              Expanded(child: _buildProgressStat('DAYS', '0', Icons.calendar_today_outlined, _navyBlue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          ],
        )
      ],
    );
  }

  Widget _buildNetworkExpansionCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: _navyBlue.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.hub_outlined, color: AppColors.goldColor, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NETWORK EXPANSION', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('EXPAND YOUR DIRECT NETWORK TO EARN 2% FLAT BONUS ON EVERY REFERRAL.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0, height: 1.5)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: _buildNetworkBadge('0', 'REFERRED', AppColors.goldBadgeBg, AppColors.goldColor)),
              const SizedBox(width: 12),
              Expanded(child: _buildNetworkBadge('₹0', 'COMM. EARNED', Colors.white, _navyBlue)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Referral Code Copy Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('YOUR REFERRAL CODE', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                    SizedBox(height: 4),
                    Text('VEV8UOMN', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.goldColor, size: 20),
                  onPressed: () => _copyToClipboard('VEV8UOMN'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _routeToReferral,
              icon: const Icon(Icons.people_alt_outlined, size: 16),
              label: const Text('VIEW NETWORK', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.0)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyToClipboard('https://vamanan.com/ref/VEV8UOMN'),
              icon: const Icon(Icons.link, size: 16),
              label: const Text('COPY LINK', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.0)),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24, width: 2), padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNetworkBadge(String value, String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildGrowthInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.show_chart, color: Colors.white, size: 16)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GROWTH INSIGHTS', style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('YOUR PROGRESS CHART • LAST 7 DAYS', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.query_stats, size: 40, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('NOT ENOUGH DATA TO GENERATE VISUAL TRENDS', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildImportantNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.goldBg, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.goldBorder, width: 2)),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.goldColor, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24)),
          const SizedBox(height: 16),
          const Text('IMPORTANT NOTICE', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          Text(
            'KYC VERIFICATION IS REQUIRED BEFORE YOU CAN USE ALL FEATURES. PLEASE COMPLETE YOUR KYC TO UNLOCK WITHDRAWALS AND FULL ACCESS TO THE PLATFORM.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.kPrimaryDark.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletOperationsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 20)),
          const SizedBox(height: 16),
          Text('WALLET OPERATIONS', style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('RECENT APPROVED PAYOUTS & DEPOSITS', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          const SizedBox(height: 32),
          Icon(Icons.receipt_long_outlined, size: 48, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('NO RECENT TRANSACTIONS DETECTED', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: _lightBorder, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.chat_bubble_outline, color: AppColors.goldColor, size: 18)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FEEDBACK & REMARKS', style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('SHARE YOUR THOUGHTS • SEE REPLIES FROM OUR TEAM', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 2),
          const SizedBox(height: 24),
          
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildFeedbackTabBtn(0, 'WRITE\nFEEDBACK'),
                _buildFeedbackTabBtn(1, 'FROM\nTEAM'),
                _buildFeedbackTabBtn(2, 'MY\nSUBMISSIONS'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildFeedbackContent(),
          )
        ],
      ),
    );
  }

  Widget _buildFeedbackTabBtn(int index, String title) {
    final isActive = _feedbackTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _feedbackTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isActive ? const Color(0xFF2563EB) : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isActive ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : []),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: isActive ? Colors.white : _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildFeedbackContent() {
    if (_feedbackTab == 0) {
      return Column(
        key: const ValueKey('WRITE'),
        children: [
          TextField(
            controller: _feedbackSubjectCtrl,
            style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            decoration: InputDecoration(hintText: 'SUBJECT (E.G. PAYOUT QUERY)', hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic), filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackMsgCtrl,
            maxLines: 4,
            style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            decoration: InputDecoration(hintText: 'YOUR MESSAGE...', hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic), filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitFeedback,
              icon: const Icon(Icons.send, size: 16),
              label: const Text('SUBMIT FEEDBACK', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          )
        ],
      );
    } else if (_feedbackTab == 1) {
      return Container(
        key: const ValueKey('TEAM'),
        padding: const EdgeInsets.symmetric(vertical: 40),
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('NO REPLIES FROM THE TEAM YET', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          ],
        ),
      );
    } else {
      return Container(
        key: const ValueKey('SUBMISSIONS'),
        padding: const EdgeInsets.symmetric(vertical: 40),
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('NO SUBMISSIONS YET', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          ],
        ),
      );
    }
  }
}