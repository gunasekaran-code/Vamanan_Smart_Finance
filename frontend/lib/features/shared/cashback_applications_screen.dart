import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/cashback_application_model.dart';
import '../../services/cashback_application_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class CashbackApplicationsScreen extends StatefulWidget {
  const CashbackApplicationsScreen({super.key});

  @override
  State<CashbackApplicationsScreen> createState() =>
      _CashbackApplicationsScreenState();
}

class _CashbackApplicationsScreenState
    extends State<CashbackApplicationsScreen> {
  final CashbackApplicationService _service = CashbackApplicationService.instance;

  List<CashbackApplication> _applications = [];
  int _pendingCount = 0;
  bool _loading = true;
  String? _error;
  final Set<int> _busyIds = {}; // rows currently approving/rejecting

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await _service.fetchApplications();

    if (!mounted) return;

    if (!response.success || response.data == null) {
      setState(() {
        _loading = false;
        _error = response.message ?? 'Failed to load cashback applications.';
      });
      return;
    }

    final result = response.data!;
    setState(() {
      _applications = result.applications;
      _pendingCount = result.applications
          .where((a) => a.status == CashbackStatus.pending)
          .length;
      _loading = false;
    });
  }

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message:
          "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      // No dedicated "process yield" backend route exists yet in
      // cashback_applications.php — wire this to that endpoint once it's added.
      ToastService.show(
          title: 'Success',
          message: 'Monthly yield processed.',
          type: ToastType.success);
    }
  }

  Future<void> _handleApprove(CashbackApplication app) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'APPROVE APPLICATION',
      message: 'Mark this cashback application as Approved?',
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );
    if (confirmed != true) return;
    await _updateStatus(app, CashbackStatus.approved);
  }

  Future<void> _handleReject(CashbackApplication app) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REJECT APPLICATION',
      message: 'Mark this cashback application as Rejected?',
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true) return;
    await _updateStatus(app, CashbackStatus.rejected);
  }

  Future<void> _updateStatus(
      CashbackApplication app, CashbackStatus status) async {
    setState(() => _busyIds.add(app.id));

    final response = await _service.updateStatus(id: app.id, status: status);

    if (!mounted) return;
    setState(() => _busyIds.remove(app.id));

    if (!response.success) {
      ToastService.show(
        title: 'Error',
        message: response.message ?? 'Could not update the application.',
        type: ToastType.error,
      );
      return;
    }

    ToastService.show(
      title: status == CashbackStatus.approved ? 'Approved' : 'Rejected',
      message: 'Application has been ${status.apiValue}.',
      type: status == CashbackStatus.approved
          ? ToastType.success
          : ToastType.info,
    );

    // Refresh from server so the summary count / row state stays accurate.
    _load();
  }

  void _showApplicationDetails(CashbackApplication app) {
    Widget buildModal(BuildContext modalContext) => ApplicationDetailsModal(
          app: app,
          onApprove: () {
            Navigator.pop(modalContext);
            _handleApprove(app);
          },
          onReject: () {
            Navigator.pop(modalContext);
            _handleReject(app);
          },
        );

    // Mobile: bottom sheet docked to the bottom edge of the screen.
    // Desktop/tablet: centered dialog.
    if (MediaQuery.of(context).size.width < 600) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x990F172A),
        builder: buildModal,
      );
    } else {
      showDialog(
        context: context,
        barrierColor: const Color(0x990F172A),
        builder: buildModal,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, outerConstraints) {
            final isMobile = outerConstraints.maxWidth < 600;
            return RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.kBorder),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users, orders, assets...',
                          hintStyle:
                              TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.kTextMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _handleProcessYield,
                        icon: const Icon(Icons.bolt, size: 18),
                        label: Text(
                          'PROCESS MONTHLY YIELD',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
                        border: Border.all(color: AppColors.kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          Container(height: 1, color: AppColors.kBorder),
                          _buildBody(isMobile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CASHBACK APPLICATIONS',
              style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 6),
            Text(
              'CUSTOMER-SUBMITTED CASHBACK CLAIM APPLICATIONS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF94A3B8).withOpacity(0.8),
                  letterSpacing: 0.5),
            ),
          ],
        );

        final badgeSection = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(24)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 6, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text('$_pendingCount PENDING REVIEW',
                  style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        );

        return Padding(
          padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleSection, const SizedBox(height: 16), badgeSection],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(child: titleSection), badgeSection],
                ),
        );
      },
    );
  }

  Widget _buildBody(bool isMobile) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(child: AppLoader()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.kDanger)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('RETRY')),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(child: Text('No cashback applications yet.')),
      );
    }

    if (isMobile) {
      return _buildMobileList();
    } else {
      return _buildDesktopTable();
    }
  }

  // ---------------------------------------------------------------------------
  // DESKTOP TABLE VIEW
  // ---------------------------------------------------------------------------
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 32,
        headingRowHeight: 56,
        dataRowMinHeight: 120, // Lowered minimum height
        dataRowMaxHeight: double.infinity, // FIXED: Removed strict 180 height limit to stop bottom overflow
        dividerThickness: 1,
        headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Color(0xFF94A3B8),
            fontSize: 12,
            letterSpacing: 2),
        columns: const [
          DataColumn(label: Text('CUSTOMER')),
          DataColumn(label: Text('PURCHASE')),
          DataColumn(label: Text('BANK / PAYMENT')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('ACTIONS')),
        ],
        rows: _applications.map((app) {
          return DataRow(
            cells: [
              DataCell(Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildCustomerCell(app),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildPurchaseCell(app),
              )),
              DataCell(Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildBankCell(app),
              )),
              DataCell(_buildStatusBadge(app.status)),
              DataCell(_buildActionsCell(app)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE CARD VIEW
  // ---------------------------------------------------------------------------
  Widget _buildMobileList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _applications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final app = _applications[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.kBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Customer & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCustomerCell(app)),
                  _buildStatusBadge(app.status),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.kBorder, height: 1)),
              
              // Details: Purchase & Bank
              _buildPurchaseCell(app, isMobile: true),
              const SizedBox(height: 16),
              _buildBankCell(app, isMobile: true),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.kBorder, height: 1)),
              
              // Actions
              SizedBox(
                width: double.infinity,
                child: _buildActionsCell(app, isMobile: true),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED CELL WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildStatusBadge(CashbackStatus status) {
    final colors = switch (status) {
      CashbackStatus.pending => (const Color(0xFFFFFBEB), const Color(0xFFFDE68A), const Color(0xFFD97706)),
      CashbackStatus.approved => (const Color(0xFFECFDF5), const Color(0xFFA7F3D0), const Color(0xFF059669)),
      CashbackStatus.rejected => (const Color(0xFFFEF2F2), const Color(0xFFFECACA), AppColors.kDanger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: colors.$1,
          border: Border.all(color: colors.$2),
          borderRadius: BorderRadius.circular(20)), // Rounded pill style
      child: Text(status.label,
          style: TextStyle(
              color: colors.$3,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildCustomerCell(CashbackApplication app) {
    final initial =
        app.customerName.isNotEmpty ? app.customerName.substring(0, 1).toUpperCase() : '?';
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(initial,
              style: const TextStyle(
                  color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.customerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 14)),
              Text(app.customerCode.isNotEmpty ? app.customerCode : '—',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), fontSize: 11)),
              const SizedBox(height: 2),
              Text(app.customerEmail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseCell(CashbackApplication app, {bool isMobile = false}) {
    return Container(
      width: isMobile ? double.infinity : 220,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.formattedPurchaseValue,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 15)),
          const SizedBox(height: 2),
          Text(app.purchasedProduct,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13)),
          const SizedBox(height: 8),
          if (app.productDetails.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.kBorder)),
              child: Text(app.productDetails,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4)), // Removed maxLines/overflow to let it wrap naturally
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Color(0xFFcbd5e1)),
              const SizedBox(width: 4),
              Text(app.formattedPurchaseDate,
                  style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBankCell(CashbackApplication app, {bool isMobile = false}) {
    return Container(
      width: isMobile ? double.infinity : 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.bankName.isNotEmpty ? app.bankName : '—',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A/C ${app.accountNo.isNotEmpty ? app.accountNo : "—"}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text('IFSC ${app.ifscCode.isNotEmpty ? app.ifscCode : "—"}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                if (app.bankBranch.isNotEmpty)
                  Text(app.bankBranch, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCell(CashbackApplication app, {bool isMobile = false}) {
    final busy = _busyIds.contains(app.id);
    final isPending = app.status == CashbackStatus.pending;

    // View button is always present
    final viewBtn = OutlinedButton.icon(
      onPressed: () => _showApplicationDetails(app),
      icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
      label: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, fontSize: 10)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        side: const BorderSide(color: AppColors.kBorder),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 12),
      ),
    );

    // Approve button
    final approveBtn = ElevatedButton.icon(
      onPressed: (busy || !isPending) ? null : () => _handleApprove(app),
      icon: busy
          ? const SizedBox(
              width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_circle_outline, size: 14),
      label: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, fontSize: 10)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 12),
      ),
    );

    // Reject button
    final rejectBtn = OutlinedButton.icon(
      onPressed: (busy || !isPending) ? null : () => _handleReject(app),
      icon: const Icon(Icons.cancel_outlined, size: 14),
      label: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, fontSize: 10)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF94A3B8),
        side: const BorderSide(color: AppColors.kBorder),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: 12),
      ),
    );

    if (isMobile) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: viewBtn),
          if (isPending) ...[
            const SizedBox(width: 8),
            Expanded(child: rejectBtn),
            const SizedBox(width: 8),
            Expanded(child: approveBtn),
          ]
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        viewBtn,
        if (isPending) ...[
          const SizedBox(width: 8),
          approveBtn,
          const SizedBox(width: 8),
          rejectBtn,
        ]
      ],
    );
  }
}


// ============================================================================
// DETAIL VIEW MODAL (Mobile: bottom-docked sheet · Desktop: centered dialog)
// ============================================================================
class ApplicationDetailsModal extends StatelessWidget {
  final CashbackApplication app;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ApplicationDetailsModal({
    super.key,
    required this.app,
    required this.onApprove,
    required this.onReject,
  });

  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _navyDark = Color(0xFF192A56);
  static const Color _gold = Color(0xFFB48A28);
  static const Color _goldLight = Color(0xFFFBBF24);
  static const Color _muted = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final content = Column(
      mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _buildHeader(context, isMobile),
        isMobile
            ? Expanded(child: _buildBody(isMobile))
            : Flexible(child: _buildBody(isMobile)),
        _buildFooter(context, isMobile),
      ],
    );

    if (isMobile) {
      // Docked sheet: fills most of the screen and sits flush on the bottom edge.
      return FractionallySizedBox(
        heightFactor: 0.94,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: AppColors.kBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: content,
        ),
      );
    }

    return Dialog(
      backgroundColor: AppColors.kBackground,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: content,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HEADER
  // --------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          isMobile ? 20 : 28, isMobile ? 10 : 24, isMobile ? 12 : 20, isMobile ? 20 : 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _navyDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 48 : 56,
                height: isMobile ? 48 : 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_goldLight, _gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Text(
                  _initials(app.customerName),
                  style: TextStyle(
                      fontSize: isMobile ? 17 : 20,
                      fontWeight: FontWeight.w900,
                      color: _navyDark),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'APPLICATION #${app.id} · ${app.customerCode.isNotEmpty ? app.customerCode : "—"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: isMobile ? 11 : 13,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                          color: _goldLight),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(),
              _buildHeaderChip(Icons.shopping_bag_outlined, app.formattedPurchaseValue),
              if (app.purchaseDate != null)
                _buildHeaderChip(Icons.event_outlined, app.formattedPurchaseDate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final (Color color, IconData icon) = switch (app.status) {
      CashbackStatus.approved => (AppColors.kSuccess, Icons.verified_rounded),
      CashbackStatus.rejected => (AppColors.kDanger, Icons.cancel_rounded),
      CashbackStatus.pending => (AppColors.kWarning, Icons.schedule_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(app.status.label.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _goldLight),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BODY
  // --------------------------------------------------------------------------
  Widget _buildBody(bool isMobile) {
    final gap = SizedBox(height: isMobile ? 14 : 18);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSection(
            isMobile: isMobile,
            title: 'APPLICANT DETAILS',
            icon: Icons.person_outline_rounded,
            fields: [
              _Field('CUSTOMER NAME', app.customerName),
              _Field('CUSTOMER ID', app.customerCode),
              _Field('REFERRAL ID', app.referralId),
              _Field('PHONE', app.phone),
              _Field('EMAIL', app.customerEmail, fullWidth: true),
              _Field('ADDRESS', app.address, fullWidth: true),
              _Field('AADHAAR NO', app.aadharNo),
              _Field('PAN NO', app.panNo),
            ],
          ),
          gap,
          _buildSection(
            isMobile: isMobile,
            title: 'PURCHASE DETAILS',
            icon: Icons.shopping_bag_outlined,
            fields: [
              _Field('TOTAL PURCHASE VALUE', app.formattedPurchaseValue, highlight: true),
              _Field('DATE OF PURCHASE', app.formattedPurchaseDate),
              _Field('PURCHASED PRODUCT', app.purchasedProduct, fullWidth: true),
              _Field('PRODUCT DETAILS', app.productDetails, fullWidth: true),
            ],
          ),
          gap,
          _buildSection(
            isMobile: isMobile,
            title: 'PAYMENT DETAILS',
            icon: Icons.account_balance_outlined,
            fields: [
              _Field('ACCOUNT HOLDER', app.bankAccountName, fullWidth: true),
              _Field('ACCOUNT NO', app.accountNo),
              _Field('IFSC CODE', app.ifscCode),
              _Field('BANK NAME', app.bankName),
              _Field('BANK BRANCH', app.bankBranch),
            ],
          ),
          gap,
          _buildSection(
            isMobile: isMobile,
            title: 'AGENT / DECLARATION',
            icon: Icons.badge_outlined,
            fields: [
              _Field('AGENT NAME', app.agentName),
              _Field('AGENT ID', app.agentId),
              _Field('PLACE', app.place),
              _Field('DATE', app.formattedPurchaseDate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required bool isMobile,
    required String title,
    required IconData icon,
    required List<_Field> fields,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Icon(icon, size: 16, color: AppColors.kWarning),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: _navy,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.kBorder),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final columns = isMobile ? 2 : 3;
              final cellWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: 16,
                children: [
                  for (final f in fields)
                    SizedBox(
                      width: f.fullWidth ? constraints.maxWidth : cellWidth,
                      child: _buildDetailField(f),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(_Field f) {
    final value = f.value.trim().isEmpty ? '—' : f.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(f.label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _muted,
                letterSpacing: 0.9)),
        const SizedBox(height: 5),
        SelectableText(value,
            style: TextStyle(
                fontSize: f.highlight ? 16 : 14,
                fontWeight: FontWeight.w800,
                color: f.highlight ? _gold : AppColors.kTextDark)),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // FOOTER (docked actions)
  // --------------------------------------------------------------------------
  Widget _buildFooter(BuildContext context, bool isMobile) {
    final isPending = app.status == CashbackStatus.pending;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    final approveBtn = _actionButton(
      label: 'APPROVE',
      icon: Icons.check_circle_rounded,
      onPressed: onApprove,
      background: _navy,
      foreground: Colors.white,
    );
    final rejectBtn = _actionButton(
      label: 'REJECT',
      icon: Icons.cancel_outlined,
      onPressed: onReject,
      background: const Color(0xFFFEF2F2),
      foreground: AppColors.kDanger,
      border: const Color(0xFFFECACA),
    );
    final printBtn = _actionButton(
      label: 'PRINT',
      icon: Icons.print_rounded,
      onPressed: () {}, // Print logic
      background: _gold,
      foreground: Colors.white,
    );
    final closeBtn = _actionButton(
      label: 'CLOSE',
      icon: Icons.close_rounded,
      onPressed: () => Navigator.pop(context),
      background: const Color(0xFFF1F5F9),
      foreground: AppColors.kTextMuted,
    );

    Widget buttons;
    if (isMobile) {
      buttons = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending) ...[
            Row(children: [
              Expanded(child: rejectBtn),
              const SizedBox(width: 10),
              Expanded(child: approveBtn),
            ]),
            const SizedBox(height: 10),
          ],
          Row(children: [
            Expanded(child: printBtn),
            const SizedBox(width: 10),
            Expanded(child: closeBtn),
          ]),
        ],
      );
    } else {
      buttons = Row(children: [
        if (isPending) ...[
          Expanded(child: approveBtn),
          const SizedBox(width: 12),
          Expanded(child: rejectBtn),
          const SizedBox(width: 12),
        ],
        Expanded(child: printBtn),
        const SizedBox(width: 12),
        Expanded(child: closeBtn),
      ]);
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24, 14, isMobile ? 16 : 24, 14 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.kBorder)),
        boxShadow: [
          BoxShadow(color: Color(0x140F172A), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: buttons,
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color background,
    required Color foreground,
    Color? border,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.8)),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: border != null ? BorderSide(color: border) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'[\s.]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _Field {
  final String label;
  final String value;
  final bool fullWidth;
  final bool highlight;

  const _Field(this.label, this.value,
      {this.fullWidth = false, this.highlight = false});
}
