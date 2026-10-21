import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_loader.dart';
import '../../services/manager_dashboard_service.dart'; 

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final ManagerDashboardService _dashboardService = ManagerDashboardService();
  late Future<Map<String, dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _dashboardService.fetchDashboardStats();
  }

  // Helper method to refresh data
  Future<void> _refreshData() async {
    setState(() {
      _dashboardDataFuture = _dashboardService.fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Manager Dashboard',
      subtitle: 'Overview of system operations & queues.',
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _dashboardDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 50.0),
                child: Center(child: AppLoader()),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load data:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasData) {
              final data = snapshot.data!;
              
              // Safely extract maps/lists from JSON
              final revenue = data['revenue'] ?? {};
              final users = data['users'] ?? {};
              final kycPendingList = data['kyc_pending'] as List<dynamic>? ?? [];
              final withdrawalsList = data['withdrawals'] as List<dynamic>? ?? [];

              return Column(
                children: [
                  _ManagerStatCardsGrid(
                    totalVolume: revenue['total_volume']?.toString() ?? '0.00',
                    totalUsers: users['total']?.toString() ?? '0',
                    activeInvestments: revenue['active_investments']?.toString() ?? '0',
                    goldPrice: data['liveGoldPrice']?.toString() ?? '0.00',
                  ),
                  const SizedBox(height: 24),
                  _KycQueueCard(kycList: kycPendingList),
                  const SizedBox(height: 24),
                  _RecentWithdrawalsCard(withdrawalsList: withdrawalsList),
                  const SizedBox(height: 32),
                ],
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
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
          color: borderColor ?? const Color(0xFFF1F5F9), 
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
  final String totalVolume;
  final String totalUsers;
  final String activeInvestments;
  final String goldPrice;

  const _ManagerStatCardsGrid({
    required this.totalVolume,
    required this.totalUsers,
    required this.activeInvestments,
    required this.goldPrice,
  });

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
      childAspectRatio: isSmallMobile ? 0.82 : 1.10, 
      children: [
        _ManagerStatCard(
          icon: Icons.account_balance_outlined,
          badgeText: 'LIVE VOLUME',
          label: 'TOTAL INVESTMENT',
          value: '₹$totalVolume',
          iconColor: AppColors.goldColor,
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
        _ManagerStatCard(
          icon: Icons.person_outline,
          badgeText: 'USERS',
          label: 'TOTAL USERS',
          value: totalUsers,
          iconColor: AppColors.kPrimary,
          backgroundColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          badgeBackgroundColor: const Color(0xFFEDF2F7),
          badgeTextColor: AppColors.kPrimary,
        ),
        _ManagerStatCard(
          icon: Icons.bolt_outlined,
          badgeText: 'ACTIVE',
          label: 'ACTIVE INVESTMENTS',
          value: activeInvestments,
          iconColor: const Color(0xFF3B82F6),
          backgroundColor: const Color(0xFFF0F7FF),
          borderColor: const Color(0xFFBFDBFE),
          badgeBackgroundColor: const Color(0xFFDBEAFE),
          badgeTextColor: const Color(0xFF1D4ED8),
        ),
        _ManagerStatCard(
          icon: Icons.trending_up_rounded,
          badgeText: '24K',
          label: 'TODAY\'S GOLD RATE',
          value: '₹$goldPrice',
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
      padding: const EdgeInsets.all(14), 
      borderRadius: 24,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          const Spacer(), 
          
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade500, 
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
  final List<dynamic> kycList;

  const _KycQueueCard({required this.kycList});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('KYC QUEUE'),
          const SizedBox(height: 16),
          if (kycList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No pending KYC requests',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            // Build dynamically from data list
            ...kycList.take(5).map((kycUser) {
              final String name = kycUser['name']?.toString().toUpperCase() ?? 'UNKNOWN';
              final String email = kycUser['email']?.toString().toUpperCase() ?? 'NO EMAIL';
              final String initial = name.isNotEmpty ? name[0] : '?';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildKycItem(initial, name, email),
              );
            }).toList(),
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
          OutlinedButton(
            onPressed: () {
               // TODO: Handle review action
            },
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
  final List<dynamic> withdrawalsList;

  const _RecentWithdrawalsCard({required this.withdrawalsList});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('RECENT WITHDRAWALS'),
          const SizedBox(height: 16),
          if (withdrawalsList.isEmpty)
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
          else
            ...withdrawalsList.take(5).map((withdrawal) {
              final String name = withdrawal['user_name']?.toString() ?? 'Unknown User';
              final String amount = withdrawal['amount']?.toString() ?? '0.00';
              final String status = withdrawal['status']?.toString().toUpperCase() ?? 'PENDING';
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                  child: const Icon(Icons.arrow_upward, color: AppColors.kPrimary, size: 16),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Status: $status', style: const TextStyle(fontSize: 11)),
                trailing: Text(
                  '₹$amount', 
                  style: const TextStyle(
                    fontWeight: FontWeight.w900, 
                    color: Colors.redAccent
                  ),
                ),
              );
            }).toList(),
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