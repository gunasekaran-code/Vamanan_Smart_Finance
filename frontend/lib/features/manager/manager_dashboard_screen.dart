import 'package:flutter/material.dart';
import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with your actual user session fetching logic
    // final user = SessionService.instance.currentUser!;

    return AppPage(
      title: 'Manager Dashboard',
      subtitle: 'Overview of system operations & queues.',
      children: const [
        _ManagerStatCardsGrid(),
        SizedBox(height: 24),
        _KycQueueCard(),
        SizedBox(height: 24),
        _RecentWithdrawalsCard(),
        SizedBox(height: 32),
      ],
    );
  }
}

// ============================================================================
// STYLED CARD CONTAINER
// ============================================================================
class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.borderColor,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 28,
  });

  final Widget child;
  final Color? borderColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? const Color(0xFFF1F5F9), // Very light gray border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================================
// TOP STAT CARDS (2x2 GRID)
// ============================================================================
class _ManagerStatCardsGrid extends StatelessWidget {
  const _ManagerStatCardsGrid();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: isSmallMobile ? 8.0 : 12.0,
      crossAxisSpacing: isSmallMobile ? 8.0 : 12.0,
      // FIXED: Lowered aspect ratio to provide more vertical space and prevent overflow
      childAspectRatio: isSmallMobile ? 0.82 : 1.10, 
      children: const [
        _ManagerStatCard(
          icon: Icons.account_balance_outlined,
          badgeText: 'LIVE VOLUME',
          label: 'TOTAL INVESTMENT',
          value: '₹35,86,430.65',
          iconColor: AppColors.goldColor,
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
        _ManagerStatCard(
          icon: Icons.person_outline,
          badgeText: '+5.2%',
          label: 'TOTAL USERS',
          value: '96',
          iconColor: AppColors.kPrimary,
          backgroundColor: Color(0xFFF8FAFC),
          borderColor: Color(0xFFE2E8F0),
          badgeBackgroundColor: Color(0xFFEDF2F7),
          badgeTextColor: AppColors.kPrimary,
        ),
        _ManagerStatCard(
          icon: Icons.bolt_outlined,
          badgeText: 'ACTIVE',
          label: 'ACTIVE TASKS',
          value: '10 Members',
          iconColor: Color(0xFF3B82F6),
          backgroundColor: Color(0xFFF0F7FF),
          borderColor: Color(0xFFBFDBFE),
          badgeBackgroundColor: Color(0xFFDBEAFE),
          badgeTextColor: Color(0xFF1D4ED8),
        ),
        _ManagerStatCard(
          icon: Icons.trending_up_rounded,
          badgeText: '24K',
          label: 'TODAY\'S GOLD RATE',
          value: '₹20,000.00',
          iconColor: AppColors.goldColor,
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
      ],
    );
  }
}

class _ManagerStatCard extends StatelessWidget {
  final IconData icon;
  final String? badgeText;
  final String label;
  final String value;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;

  const _ManagerStatCard({
    required this.icon,
    this.badgeText,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      // FIXED: Reduced padding slightly to prevent constraint violations
      padding: const EdgeInsets.all(14), 
      borderRadius: 24,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon and Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: badgeTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          
          // FIXED: Spacer automatically pushes the text to the bottom without overflowing
          const Spacer(), 
          
          // Bottom Row: Label and Value
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade500, // Slightly darker for better readability on colored bgs
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: iconColor == AppColors.goldColor ? AppColors.kPrimary : iconColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// KYC QUEUE CARD
// ============================================================================
class _KycQueueCard extends StatelessWidget {
  const _KycQueueCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('KYC QUEUE'),
          const SizedBox(height: 24),
          _buildKycItem('A', 'ARUMUGAM PONNUSAMY', 'ARUMUGAMMONISH123@GMAIL.COM'),
          const SizedBox(height: 16),
          _buildKycItem('V', 'VASUNDHARA', 'SUNDARENTERPRISES17@GMAIL.COM'),
          const SizedBox(height: 16),
          _buildKycItem('V', 'VIGNESH', 'VIKY009426@GMAIL.COM'),
        ],
      ),
    );
  }

  Widget _buildKycItem(String initial, String name, String email) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar Square (Squircle)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.kPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Review Button
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kPrimary,
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'REVIEW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECENT WITHDRAWALS CARD
// ============================================================================
class _RecentWithdrawalsCard extends StatelessWidget {
  const _RecentWithdrawalsCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('RECENT WITHDRAWALS'),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No recent withdrawals',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER HEADER FOR SECTION CARDS
// ============================================================================
Widget _buildHeader(String title) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: AppColors.kPrimary,
          letterSpacing: 0.5,
        ),
      ),
      InkWell(
        onTap: () {},
        child: Text(
          'VIEW ALL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Colors.amber.shade700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ],
  );
}