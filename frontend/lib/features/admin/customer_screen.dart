import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// ============================================================================
// DATA MODEL
// ============================================================================
class CustomerModel {
  final String id;
  final String name;
  final String joinedDate;
  final double walletBalance;
  final String status;
  final bool isNewRequest;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.joinedDate,
    required this.walletBalance,
    required this.status,
    this.isNewRequest = false,
  });
}

// ============================================================================
// MAIN SCREEN
// ============================================================================
class CustomerDirectoryScreen extends StatefulWidget {
  const CustomerDirectoryScreen({super.key});

  @override
  State<CustomerDirectoryScreen> createState() => _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends State<CustomerDirectoryScreen> {
  // Mock data matching the provided design image
  final List<CustomerModel> _customers = [
    const CustomerModel(
      id: '1',
      name: 'SIVAKUMAR. VK',
      joinedDate: '10/8/2026',
      walletBalance: 0,
      status: 'ACTIVE',
    ),
    const CustomerModel(
      id: '2',
      name: 'SIVAKUMAR.N',
      joinedDate: '8/8/2026',
      walletBalance: 0,
      status: 'ACTIVE',
    ),
    const CustomerModel(
      id: '3',
      name: 'SIVAKAMI. V',
      joinedDate: '8/8/2026',
      walletBalance: 0,
      status: 'PENDING REVIEW',
      isNewRequest: true,
    ),
  ];

  final TextEditingController _searchController = TextEditingController(text: 'SIVA');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Action Handlers ---
  Future<void> _handleSuspend(CustomerModel customer) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'SUSPEND ACCOUNT',
      message: 'Are you sure you want to suspend access for ${customer.name}? They will no longer be able to log in.',
      confirmLabel: 'SUSPEND',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      ToastService.show(
        title: 'Account Suspended',
        message: '${customer.name}\'s account has been successfully suspended.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _handleGrantAccess(CustomerModel customer) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'GRANT LOGIN ACCESS',
      message: 'Approve the request and grant login credentials to ${customer.name}?',
      confirmLabel: 'APPROVE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kPrimary, // Deep Navy Blue
    );

    if (confirmed == true && mounted) {
      ToastService.show(
        title: 'Access Granted',
        message: 'Login credentials have been approved for ${customer.name}.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(isMobile ? 32 : 40),
              border: Border.all(color: AppColors.kBorder.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kPrimary.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // FIXED: Re-added the missing children (Header & Cards)
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 32),
                
                // Customer Cards Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      // Mobile view: Stack vertically
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _customers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          return _CustomerCard(
                            customer: _customers[index],
                            onSuspend: () => _handleSuspend(_customers[index]),
                            onGrantAccess: () => _handleGrantAccess(_customers[index]),
                          );
                        },
                      );
                    }
                    // Tablet/Desktop view: Wrap side-by-side
                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: _customers.map((c) => SizedBox(
                        width: 340, // Slightly wider for better desktop layout
                        child: _CustomerCard(
                          customer: c,
                          onSuspend: () => _handleSuspend(c),
                          onGrantAccess: () => _handleGrantAccess(c),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER SECTION
  // ===========================================================================
  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.folder_shared_outlined, color: AppColors.goldColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'INVESTOR DIRECTORY',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStylishSearchBar(fullWidth: true),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: const [
            Icon(Icons.folder_shared_outlined, color: AppColors.goldColor, size: 32),
            SizedBox(width: 16),
            Text(
              'INVESTOR DIRECTORY',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        _buildStylishSearchBar(fullWidth: false),
      ],
    );
  }

  // ===========================================================================
  // STYLISH SEARCH BAR
  // ===========================================================================
  Widget _buildStylishSearchBar({required bool fullWidth}) {
    return Container(
      width: fullWidth ? double.infinity : 360,
      height: 56, // Slightly taller for a more premium feel
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28), // Pill-shaped
        border: Border.all(color: AppColors.kBorder.withOpacity(0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: AppColors.kPrimary,
          letterSpacing: 0.5,
        ),
        decoration: InputDecoration(
          hintText: 'SEARCH DIRECTORY...',
          hintStyle: TextStyle(
            color: AppColors.kTextMuted.withOpacity(0.6),
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
          // Leading Search Icon
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 20.0, right: 12.0),
            child: Icon(Icons.search_rounded, color: AppColors.goldColor, size: 24),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          // Trailing Filter Icon
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.kPrimary, size: 20),
              onPressed: () {
                // TODO: Add filter bottom sheet or logic here
              },
              splashRadius: 20,
              tooltip: 'Advanced Filters',
            ),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOMER CARD WIDGET
// ============================================================================
class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onSuspend;
  final VoidCallback onGrantAccess;

  const _CustomerCard({
    required this.customer,
    required this.onSuspend,
    required this.onGrantAccess,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = customer.status == 'PENDING REVIEW';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Ultra-light slate background
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.6)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityRow(),
                const SizedBox(height: 24),
                
                _buildMetricsRow(),
                const SizedBox(height: 24),
                
                const Divider(color: AppColors.kBorder, height: 1),
                const SizedBox(height: 24),
                
                _buildActionButton(isPending),
              ],
            ),
          ),

          // 'NEW REQUEST' Ribbon Overlay
          if (customer.isNewRequest)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.goldColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(32),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'NEW REQUEST',
                  style: TextStyle(
                    color: AppColors.kSurface,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdentityRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar Squircle
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.kPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.kPrimary.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            customer.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: AppColors.goldColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Name & Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: const TextStyle(
                  color: AppColors.kPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: AppColors.kTextMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'JOINED ${customer.joinedDate}',
                      style: const TextStyle(
                        color: AppColors.kTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            label: 'WALLET',
            value: '₹${customer.walletBalance.toInt()}',
            valueColor: AppColors.kPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            label: 'STATUS',
            value: customer.status,
            valueColor: AppColors.goldColor,
            showDot: true,
            dotColor: AppColors.goldColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color valueColor,
    bool showDot = false,
    Color? dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (showDot) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isPending) {
    if (isPending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onGrantAccess,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimary, 
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: AppColors.kPrimary.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline, color: AppColors.goldColor, size: 20),
              SizedBox(width: 8),
              Text(
                'GRANT LOGIN ACCESS',
                style: TextStyle(
                  color: AppColors.goldColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onSuspend,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kPrimary,
          backgroundColor: AppColors.kSurface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.kBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.gpp_maybe_outlined, color: Colors.blueAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'SUSPEND ACCOUNT',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}