import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart'; // Adjust import based on your project structure

class AuditorRulesScreen extends StatelessWidget {
  const AuditorRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Building a custom header to match the design perfectly
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700), // Perfect for mobile & tablet
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER
                Row(
                  children: const [
                    Icon(Icons.star, color: AppColors.goldColor, size: 10),
                    SizedBox(width: 6),
                    Text(
                      'HOW IT WORKS',
                      style: TextStyle(
                        color: AppColors.goldColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'RULES',
                  style: TextStyle(
                    color: AppColors.kPrimaryDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'HOW OUR CASHBACK AND REFERRAL PROGRAM WORKS',
                  style: TextStyle(
                    color: AppColors.kTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 32),

                // 2. CARD: HOW YOU EARN
                _buildHowYouEarnCard(),
                const SizedBox(height: 24),

                // 3. CARD: REFERRAL PROGRAM
                _buildReferralProgramCard(),
                const SizedBox(height: 24),

                // 4. CARD: DIRECTIVES (NAVY CARD)
                _buildDirectivesCard(),
                const SizedBox(height: 24),

                // 5. CARD: EXAMPLE
                _buildExampleCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // SECTION CARDS
  // ==========================================================================

  Widget _buildHowYouEarnCard() {
    return _BaseRuleCard(
      watermarkIcon: Icons.bolt,
      children: [
        _buildCardHeader(
          title: 'HOW YOU EARN',
          icon: Icons.card_giftcard,
          iconBg: AppColors.kPrimaryDark,
          iconColor: AppColors.goldColor,
          titleColor: AppColors.kPrimaryDark,
        ),
        const SizedBox(height: 32),
        _buildRuleItem(
          icon: Icons.percent,
          title: '10% MONTHLY CASHBACK',
          description: 'EARN 10% CASHBACK EVERY MONTH — YOUR FULL PURCHASE VALUE IS RETURNED OVER 10 MONTHS.',
        ),
        _buildRuleItem(
          icon: Icons.calendar_today_outlined,
          title: '10 MONTHS TOTAL',
          description: 'CASHBACK IS PAID MONTHLY FOR 10 MONTHS (10% EACH MONTH = 100%). REFERRAL INCOME IS INCLUDED AND THE COMBINED TOTAL IS CAPPED AT 100% OF YOUR PURCHASE AMOUNT.',
        ),
        _buildRuleItem(
          icon: Icons.access_time,
          title: 'STARTS IN 24 HOURS',
          description: 'YOUR FIRST MONTHLY CASHBACK IS CREDITED ONE MONTH AFTER YOUR PURCHASE IS APPROVED.',
        ),
        _buildRuleItem(
          icon: Icons.warning_amber_rounded,
          title: 'EARNINGS LIMIT',
          description: 'MONTHLY CASHBACK STOPS AUTOMATICALLY ONCE YOUR COMBINED CASHBACK + REFERRAL REACHES 100% OF YOUR PURCHASE AMOUNT.',
          iconColor: Colors.blue.shade300,
        ),
      ],
    );
  }

  Widget _buildReferralProgramCard() {
    return _BaseRuleCard(
      watermarkIcon: Icons.people_outline,
      children: [
        _buildCardHeader(
          title: 'REFERRAL PROGRAM',
          icon: Icons.people_alt,
          iconBg: AppColors.kPrimaryDark,
          iconColor: AppColors.goldColor,
          titleColor: AppColors.kPrimaryDark,
        ),
        const SizedBox(height: 32),
        _buildRuleItem(
          icon: Icons.verified_user_outlined,
          title: 'ELIGIBILITY',
          description: 'YOU NEED 10 DIRECT REFERRALS WHO HAVE MADE A PURCHASE TO UNLOCK REFERRAL COMMISSIONS.',
        ),
        _buildRuleItem(
          icon: Icons.monetization_on_outlined,
          title: 'FLAT REFERRAL COMMISSION',
          description: '', // Desc handled by the custom box below
          hasBottomPadding: false,
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.only(left: 36), // Aligned with text from RuleItem
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('EVERY DIRECT REFERRAL', style: TextStyle(color: AppColors.kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              SizedBox(height: 4),
              Text('2%', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 32, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
              SizedBox(height: 4),
              Text('FLAT / ON PURCHASE VALUE', style: TextStyle(color: AppColors.kTextMuted, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectivesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kPrimaryDark, // Navy Blue Background
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.kPrimaryDark.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          // Faint Watermark
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.shield_outlined, size: 180, color: Colors.white.withOpacity(0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(
                  title: 'DIRECTIVES',
                  icon: Icons.admin_panel_settings,
                  iconBg: AppColors.goldColor,
                  iconColor: AppColors.kPrimaryDark,
                  titleColor: Colors.white,
                ),
                const SizedBox(height: 32),
                _buildBulletPoint('KYC VERIFICATION IS REQUIRED BEFORE YOU CAN USE ALL FEATURES.'),
                _buildBulletPoint('YOU CAN SELL YOUR GOLD BACK TO US ANYTIME.'),
                _buildBulletPoint('ANY FRAUDULENT ACTIVITY WILL RESULT IN ACCOUNT TERMINATION.'),
                _buildBulletPoint('ONLY SHARE YOUR OWN REFERRAL CODE.'),
                _buildBulletPoint('ALL YOUR EARNINGS ARE CREDITED TO YOUR WALLET.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard() {
    return _BaseRuleCard(
      watermarkIcon: Icons.account_balance,
      children: [
        _buildCardHeader(
          title: 'EXAMPLE',
          icon: Icons.account_balance,
          iconBg: AppColors.kPrimaryDark,
          iconColor: AppColors.goldColor,
          titleColor: AppColors.kPrimaryDark,
        ),
        const SizedBox(height: 32),
        
        _buildExampleStat('YOUR PURCHASE', '₹50,000', valueColor: AppColors.kPrimaryDark),
        const SizedBox(height: 24),
        
        _buildExampleStat('MONTHLY CASHBACK (10%)', '₹5,000 / month', valueColor: AppColors.goldColor),
        const SizedBox(height: 24),
        
        _buildExampleStat('DURATION', '10 months', valueColor: AppColors.kPrimaryDark),
        const SizedBox(height: 24),
        
        _buildExampleStat('TOTAL EARNINGS', '₹50,000 (100%)', valueColor: AppColors.goldColor),
        const SizedBox(height: 32),

        // Gold Info Box
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.goldBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.goldBorder, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.bolt, color: AppColors.goldColor, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ACTIVATION OF 10 QUALIFIED NODES ENABLES AUXILIARY COMMISSIONS BEYOND DIURNAL YIELDS.',
                  style: TextStyle(
                    color: AppColors.goldColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // ==========================================================================
  // HELPER WIDGETS
  // ==========================================================================

  Widget _buildCardHeader({required String title, required IconData icon, required Color iconBg, required Color iconColor, required Color titleColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem({required IconData icon, required String title, required String description, Color? iconColor, bool hasBottomPadding = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: hasBottomPadding ? 24.0 : 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? AppColors.goldColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.kPrimaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.kTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                height: 1.5,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleStat(String label, String value, {required Color valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.kTextMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// Reusable Base Card with Watermark
class _BaseRuleCard extends StatelessWidget {
  final List<Widget> children;
  final IconData watermarkIcon;

  const _BaseRuleCard({required this.children, required this.watermarkIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          // Background Watermark Icon
          Positioned(
            right: -20,
            top: 20,
            child: Icon(watermarkIcon, size: 200, color: const Color(0xFFF8FAFC).withOpacity(0.8)), // Extremely faint
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}