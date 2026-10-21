import 'package:flutter/material.dart';
import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../services/advocate_dashboard_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AdvocatorDashboardScreen extends StatefulWidget {
  const AdvocatorDashboardScreen({super.key});

  @override
  State<AdvocatorDashboardScreen> createState() =>
      _AdvocatorDashboardScreenState();
}

class _AdvocatorDashboardScreenState extends State<AdvocatorDashboardScreen> {
  final AdvocateDashboardService _dashboardService = AdvocateDashboardService();
  late Future<Map<String, dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _dashboardService.fetchDashboardStats();
  }

  Future<void> _refreshData() async {
    setState(() {
      _dashboardDataFuture = _dashboardService.fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Advocator Dashboard',
      subtitle: 'Overview of agreements, approvals & customer disputes.',
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
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
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
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasData) {
              final data = snapshot.data!;

              final stats = data['stats'] as Map<String, dynamic>? ?? {};
              final agreements = data['agreements'] as List<dynamic>? ?? [];
              final activities = data['activities'] as List<dynamic>? ?? [];

              // "Pending signature approvals" = agreements awaiting advocate
              // action, matching the same 'verified' status the backend
              // uses to compute stats['pending_agreements'].
              final pendingApprovals = agreements
                  .where((a) => a['status']?.toString() == 'verified')
                  .toList();

              return Column(
                children: [
                  _AdvocatorStatCardsGrid(
                    totalCustomers: stats['active_members']?.toString() ?? '0',
                    approvedAgreements:
                        stats['active_agreements']?.toString() ?? '0',
                    pendingApprovals:
                        stats['pending_agreements']?.toString() ?? '0',
                    openDisputes: stats['active_disputes']?.toString() ?? '0',
                  ),
                  const SizedBox(height: 32),
                  _PendingSignatureApprovalsCard(
                      pendingApprovals: pendingApprovals),
                  const SizedBox(height: 32),
                  _AuditLogsCard(activities: activities),
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
          color:
              borderColor ?? const Color(0xFFF1F5F9), // Very light gray border
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
// TOP STAT CARDS (2x2 GRID) - MATCHING MANAGER DASHBOARD UI
// ============================================================================
class _AdvocatorStatCardsGrid extends StatelessWidget {
  final String totalCustomers;
  final String approvedAgreements;
  final String pendingApprovals;
  final String openDisputes;

  const _AdvocatorStatCardsGrid({
    required this.totalCustomers,
    required this.approvedAgreements,
    required this.pendingApprovals,
    required this.openDisputes,
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
        _AdvocatorStatCard(
          icon: Icons.people_outline,
          badgeText: 'USERS',
          label: 'TOTAL CUSTOMERS',
          value: totalCustomers,
          iconColor: AppColors.kPrimary,
          backgroundColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          badgeBackgroundColor: const Color(0xFFEDF2F7),
          badgeTextColor: AppColors.kPrimary,
        ),
        _AdvocatorStatCard(
          icon: Icons.check_circle_outline,
          badgeText: 'APPROVED',
          label: 'APPROVED AGREEMENTS',
          value: approvedAgreements,
          iconColor: const Color(0xFF3B82F6),
          backgroundColor: const Color(0xFFF0F7FF),
          borderColor: const Color(0xFFBFDBFE),
          badgeBackgroundColor: const Color(0xFFDBEAFE),
          badgeTextColor: const Color(0xFF1D4ED8),
        ),
        _AdvocatorStatCard(
          icon: Icons.access_time,
          badgeText: 'PENDING',
          label: 'PENDING APPROVALS',
          value: pendingApprovals,
          iconColor: AppColors.goldColor,
          backgroundColor: AppColors.goldBg,
          borderColor: AppColors.goldBorder,
          badgeBackgroundColor: AppColors.goldBadgeBg,
          badgeTextColor: AppColors.goldColor,
        ),
        _AdvocatorStatCard(
          icon: Icons.error_outline,
          badgeText: 'DISPUTES',
          label: 'OPEN DISPUTES',
          value: openDisputes,
          iconColor: const Color(0xFFEF4444), // Soft Red theme for disputes
          backgroundColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          badgeBackgroundColor: const Color(0xFFFEE2E2),
          badgeTextColor: const Color(0xFFB91C1C),
        ),
      ],
    );
  }
}

class _AdvocatorStatCard extends StatelessWidget {
  final IconData icon;
  final String? badgeText;
  final String label;
  final String value;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;

  const _AdvocatorStatCard({
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                // Match Manager logic: Gold uses primary text color, else use icon color
                color: iconColor == AppColors.goldColor
                    ? AppColors.kPrimary
                    : iconColor,
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
// PENDING SIGNATURE APPROVALS
// ============================================================================
class _PendingSignatureApprovalsCard extends StatelessWidget {
  final List<dynamic> pendingApprovals;

  const _PendingSignatureApprovalsCard({required this.pendingApprovals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PENDING SIGNATURE APPROVALS'),
        const SizedBox(height: 16),
        _DashboardCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'CUSTOMER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'VIEW DETAILS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                  height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),

              if (pendingApprovals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'NO PENDING APPROVALS FOUND',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFCBD5E1), // Light Slate
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                )
              else
                ...pendingApprovals.take(6).map((agreement) {
                  final name =
                      agreement['user_name']?.toString() ?? 'Unknown Customer';
                  final product = agreement['product_name']?.toString();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.kPrimary,
                                    ),
                                  ),
                                  if (product != null &&
                                      product.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      product,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to agreement detail / signature screen.
                              },
                              child: Text(
                                'VIEW',
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
                        ),
                      ),
                      const Divider(
                          height: 1, color: Color(0xFFF1F5F9), thickness: 1.0),
                    ],
                  );
                }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// AUDIT LOGS
// ============================================================================
class _AuditLogsCard extends StatelessWidget {
  final List<dynamic> activities;

  const _AuditLogsCard({required this.activities});

  void _clearLogs(BuildContext context) async {
    final confirm = await AppConfirmDialog.show(
      context: context,
      title: 'Clear Audit Logs',
      message:
          'Are you sure you want to clear the audit history? This action cannot be undone.',
      confirmLabel: 'Clear Logs',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirm == true) {
      ToastService.show(
        title: 'Logs Cleared',
        message: 'The audit history has been successfully wiped.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('AUDIT LOGS'),
            IconButton(
              onPressed: () => _clearLogs(context),
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Color(0xFF94A3B8)),
              tooltip: 'Clear Logs',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: const Center(
              child: Text(
                'NO HISTORY LOGGED...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFFCBD5E1),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          )
        else
          _DashboardCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Column(
              children: activities.map((log) {
                // Field names fall back gracefully in case your
                // activity_logs table uses different column names.
                final userName = log['user_name']?.toString() ?? 'System';
                final action = log['action']?.toString() ??
                    log['description']?.toString() ??
                    log['details']?.toString() ??
                    'Activity recorded';
                final createdAt = log['created_at']?.toString() ?? '';

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.kPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$userName — $action',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.kPrimary,
                              ),
                            ),
                            if (createdAt.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                createdAt,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// HELPER HEADER FOR SECTION TITLES
// ============================================================================
Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: AppColors.kTextDark, // Ensuring heavy navy appearance
      letterSpacing: -0.5,
    ),
  );
}
