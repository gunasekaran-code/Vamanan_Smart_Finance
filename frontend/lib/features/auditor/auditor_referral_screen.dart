import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/auditor_referral_model.dart';
import '../../services/auditor_referral_service.dart';
import 'referral_tree_widget.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AuditorReferralScreen extends StatefulWidget {
  // Wire this to however your app currently identifies the logged-in user
  // (session/provider/auth service) at the call site.
  final String userId;

  const AuditorReferralScreen({super.key, required this.userId});

  @override
  State<AuditorReferralScreen> createState() => _AuditorReferralScreenState();
}

class _AuditorReferralScreenState extends State<AuditorReferralScreen> {
  // Theme Color Aliases for cleaner code
  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _slateText = AppColors.kTextMuted;
  final Color _lightBorder = const Color(0xFFF1F5F9);
  final Color _lightBg = const Color(0xFFF8FAFC);

  final _currency = NumberFormat('#,##0', 'en_IN');

  late Future<ReferralSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = ReferralService.instance.fetchSummary(widget.userId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = ReferralService.instance.fetchSummary(widget.userId);
    });
    await _future.catchError((_) => ReferralSummary.empty());
  }

  String _money(double v) => '₹${_currency.format(v)}';

  // --- ACTIONS ---
  void _handleCopyLink(String referralCode) {
    final link = 'https://www.vamananenterprisesv.com/register?ref=$referralCode';
    Clipboard.setData(ClipboardData(text: link));
    ToastService.show(
      title: 'Link Copied',
      message: 'Your referral link has been copied to the clipboard.',
      type: ToastType.success,
    );
  }

  void _handleWhatsAppShare() {
    ToastService.show(
      title: 'WhatsApp Share',
      message: 'Opening WhatsApp to share your referral code...',
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return AppPage(
      title: null, // Custom header
      children: [
        Center(
          child: Container(
                        constraints: const BoxConstraints(maxWidth: 800), 
            child: FutureBuilder<ReferralSummary>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 120),
                    child: Center(child: AppLoader()),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final data = snapshot.data ?? ReferralSummary.empty();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. HEADER
                    Text(
                      'REFERRAL NETWORK',
                      style: TextStyle(color: _navyBlue, fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'YOUR REFERRAL NETWORK & EARNINGS',
                      style: TextStyle(color: _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 32),

                    // 2. MAIN REFERRAL CARD
                    _buildMainReferralCard(data),
                    const SizedBox(height: 24),

                    // 3. STATS GRID (2x2)
                    _buildStatsGrid(isMobile, data),
                    const SizedBox(height: 24),

                    // 4. EARNINGS STRUCTURE CARD
                    _buildEarningsStructureCard(data),
                    const SizedBox(height: 24),

                    // 5. COMMISSION RULES CARD
                    _buildCommissionRulesCard(data),
                    const SizedBox(height: 24),

                    // 6. REFERRAL TREE (genealogy, L1–L5)
                    ReferralTreeWidget(userId: widget.userId, commissionRate: data.commissionRate),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: _slateText),
          const SizedBox(height: 12),
          Text(
            'COULD NOT LOAD REFERRAL DATA',
            style: TextStyle(color: _navyBlue, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          Text(message, style: TextStyle(color: _slateText, fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _reload, child: const Text('RETRY')),
        ],
      ),
    );
  }

  // ==========================================================================
  // 1. MAIN REFERRAL CARD
  // ==========================================================================
  Widget _buildMainReferralCard(ReferralSummary data) {
    final code = data.referralCode;
    final codeHead = code.length >= 3 ? code.substring(0, 3) : code;
    final codeTail = code.length >= 3 ? code.substring(3) : '';
    final capPct = ((data.totalNetworkEarnings + data.userInvestment > 0 &&
                data.userInvestment > 0)
            ? ((data.totalNetworkEarnings / data.userInvestment) * 100)
                .clamp(0, 100)
            : 0)
        .toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            top: 40,
            child: Icon(Icons.hub_outlined, size: 140, color: const Color(0xFFF1F5F9).withOpacity(0.5)),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.goldBadgeBg, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.star, color: AppColors.goldColor, size: 10),
                      SizedBox(width: 6),
                      Text('VAMANAN', style: TextStyle(color: AppColors.goldColor, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('YOUR REFERRAL CODE', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0, fontFamily: AppColors.fontFamily),
                    children: [
                      TextSpan(text: codeHead, style: const TextStyle(color: AppColors.goldColor)),
                      TextSpan(text: codeTail, style: TextStyle(color: _navyBlue)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleCopyLink(data.referralCode),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('COPY LINK', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.0)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 10,
                          shadowColor: _navyBlue.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _handleWhatsAppShare,
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('WHATSAPP', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.0)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.goldColor,
                          backgroundColor: AppColors.goldBg,
                          side: const BorderSide(color: AppColors.goldBorder, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _lightBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _lightBorder),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10, top: 10,
                        child: Icon(Icons.trending_up, size: 80, color: const Color(0xFFE2E8F0).withOpacity(0.5)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL NETWORK EARNINGS (NET)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                          const SizedBox(height: 8),
                          Text(_money(data.totalNetworkEarnings), style: TextStyle(color: _navyBlue, fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(child: _buildSubStat('TODAY', '+${_money(data.todayEarnings)}', AppColors.goldColor)),
                              Expanded(child: _buildSubStat('MEMBERS', '${data.directCount}', const Color(0xFF3B82F6))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, thickness: 1.5, color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL EARNINGS LIMIT', style: TextStyle(color: Color(0xFF1E293B), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                              Text('$capPct% / 100%', style: const TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'YOUR TOTAL EARNINGS (CASHBACK + REFERRAL) ARE CAPPED AT 100% OF YOUR PURCHASE AMOUNT. ONCE YOU REACH IT, YOU PLAN IS COMPLETE.',
                            style: TextStyle(color: _slateText, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5, height: 1.5),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
      ],
    );
  }

  // ==========================================================================
  // 2. STATS GRID
  // ==========================================================================
  Widget _buildStatsGrid(bool isMobile, ReferralSummary data) {
    final eligibleCount = data.directCount.clamp(0, ReferralSummary.directLinkCap);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.6 : 2.5,
      children: [
        _buildGridStatCard('DIRECT REFERRALS', '${data.directCount}', Icons.people_outline, AppColors.goldBadgeBg, AppColors.goldColor),
        _buildGridStatCard('UPCOMING / BONUS', '${data.commissionRate} / referral', Icons.percent, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
        _buildGridStatCard('ELIGIBLE / CAP', '$eligibleCount / ${ReferralSummary.directLinkCap}', Icons.verified_user_outlined, AppColors.goldBadgeBg, AppColors.goldColor),
        _buildGridStatCard('TOTAL EARNINGS', _money(data.totalNetworkEarnings), Icons.trending_up, const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _buildGridStatCard(String title, String value, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const Spacer(),
          Text(title, style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: _navyBlue, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. EARNINGS STRUCTURE CARD
  // ==========================================================================
  Widget _buildEarningsStructureCard(ReferralSummary data) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REFERRAL EARNINGS STRUCTURE', style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('SIMPLE & FLAT — YOU EARN ON YOUR OWN PURCHASE AND A BONUS ON EVERY DIRECT REFERRAL', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0, height: 1.5)),
          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const Text('YOU', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0)),
                const SizedBox(height: 6),
                Text('${data.dailyCashbackRate} DAILY CASHBACK', style: const TextStyle(color: AppColors.goldColor, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          Center(child: Container(width: 3, height: 24, color: AppColors.goldColor)),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DIRECT\nREFERRAL', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      Text('${data.commissionRate} / day', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Container(width: 2, height: 40, color: Colors.white.withOpacity(0.3)),
                const SizedBox(width: 16),
                const Expanded(
                  flex: 3,
                  child: Text('Flat bonus on every direct investor you bring in — no levels, no tree.', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, height: 1.4)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'TOTAL POTENTIAL: ${data.dailyCashbackRate} OWN DAILY CASHBACK + ${data.commissionRate} FLAT ON EACH DIRECT REFERRAL',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0, height: 1.5),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================================================
  // 4. REFERRAL COMMISSION RULES CARD
  // ==========================================================================
  Widget _buildCommissionRulesCard(ReferralSummary data) {
    final filled = data.directCount.clamp(0, ReferralSummary.directLinkCap);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REFERRAL COMMISSION RULES', style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'YOU EARN REFERRAL COMMISSION FROM YOUR FIRST ${ReferralSummary.directLinkCap} DIRECT MEMBERS. AFTER ${ReferralSummary.directLinkCap} MEMBERS, REFERRAL COMMISSION STOPS, BUT YOUR OWN DAILY CASHBACK CONTINUES UNTIL YOU REACH THE 100% LIMIT.',
                  style: TextStyle(color: _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5, height: 1.5),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.goldBadgeBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.goldColor, size: 12),
                const SizedBox(width: 6),
                Text(
                  data.referralActive ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DIRECT LINK PROGRESS', style: TextStyle(color: Color(0xFF1E293B), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              Text('$filled / ${ReferralSummary.directLinkCap} ELIGIBLE DIRECT LINKS', style: const TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: List.generate(ReferralSummary.directLinkCap, (index) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index < filled ? _navyBlue : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
