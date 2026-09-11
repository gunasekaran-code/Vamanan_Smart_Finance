import 'package:flutter/material.dart';
import 'package:frontend/core/models/user_role.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class AdvocatorDashboardScreen extends StatelessWidget {
  const AdvocatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return AppPage(
      title: 'Advocator Dashboard',
      subtitle: 'Overview of agreements, approvals & customer disputes.',
      children: const [
        _AdvocatorStatCardsGrid(),
        SizedBox(height: 32),
        _PendingSignatureApprovalsCard(),
        SizedBox(height: 32),
        _AuditLogsCard(),
        SizedBox(height: 32),
      ],
    );
  }
}

// ============================================================================
// STYLED CARD CONTAINER (Reused from your base code)
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
class _AdvocatorStatCardsGrid extends StatelessWidget {
  const _AdvocatorStatCardsGrid();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      crossAxisSpacing: isSmallMobile ? 8.0 : 16.0,
      childAspectRatio: isSmallMobile ? 0.82 : 1.05, 
      children: [
        _AdvocatorStatCard(
          icon: Icons.people_outline,
          label: 'TOTAL CUSTOMERS',
          value: '0',
          iconColor: Colors.amber.shade400,
        ),
        _AdvocatorStatCard(
          icon: Icons.check_circle_outline,
          label: 'APPROVED AGREEMENTS',
          value: '10',
          iconColor: Colors.amber.shade400,
        ),
        _AdvocatorStatCard(
          icon: Icons.access_time,
          label: 'PENDING APPROVALS',
          value: '0',
          iconColor: Colors.amber.shade400,
        ),
        _AdvocatorStatCard(
          icon: Icons.error_outline,
          label: 'OPEN DISPUTES',
          value: '0',
          iconColor: Colors.blue.shade300, // Slight blue tint matching the image
        ),
      ],
    );
  }
}

class _AdvocatorStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _AdvocatorStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(20), 
      borderRadius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Raised Soft Circular Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          
          const Spacer(), 
          
          // Label and Value
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8), // Slate 400
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kTextDark, // Navy/Dark color from your theme
                letterSpacing: -1.0,
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
  const _PendingSignatureApprovalsCard();

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
              
              // Empty State Body
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
              ),
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
  const _AuditLogsCard();

  void _clearLogs(BuildContext context) async {
    final confirm = await AppConfirmDialog.show(
      context: context,
      title: 'Clear Audit Logs',
      message: 'Are you sure you want to clear the audit history? This action cannot be undone.',
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
            // Added interactive button to demonstrate Toast and Confirm Dialog
            IconButton(
              onPressed: () => _clearLogs(context),
              icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFF94A3B8)),
              tooltip: 'Clear Logs',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            // Simulating the dashed border look from the image using a light border
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