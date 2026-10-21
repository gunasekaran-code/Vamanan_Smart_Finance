import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'identity_review_screen.dart';
import '../../models/identity_verification_model.dart';
import '../../services/identity_verification_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final IdentityVerificationService _service =
      IdentityVerificationService.instance;

  /// The whole register. `admin/all_users.php` has no status parameter, so
  /// everything is fetched once and sliced here — which also gives the tabs
  /// their counts without extra round trips.
  List<IdentityRequest> _all = [];
  IdentityFilter _filter = IdentityFilter.pending;
  bool _loading = true;
  String? _error;

  /// Ids with an action in flight, so their row can show a spinner and the
  /// buttons cannot be double-tapped.
  final Set<String> _busy = {};

  List<IdentityRequest> get _visible =>
      _all.where(_filter.matches).toList(growable: false);

  int _countFor(IdentityFilter filter) => _all.where(filter.matches).length;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchRequests();
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
    } on IdentityVerificationException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// Applies a decision and keeps the row, restamped, so it moves between the
  /// tabs instead of vanishing — a rejected user still has to be findable.
  Future<void> _applyStatus(
    IdentityRequest request,
    String status, {
    required String successTitle,
    required ToastType toastType,
  }) async {
    setState(() => _busy.add(request.id));
    try {
      await _service.updateStatus(request.id, status);
      if (!mounted) return;
      setState(() {
        final i = _all.indexWhere((r) => r.id == request.id);
        if (i != -1) _all[i] = _all[i].copyWithStatus(status);
      });
      ToastService.show(
        title: successTitle,
        message: '${request.name} is now ${status.toUpperCase()}.',
        type: toastType,
      );
    } on IdentityVerificationException catch (e) {
      if (mounted) _toastError(e.message);
    } catch (e) {
      if (mounted) _toastError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy.remove(request.id));
    }
  }

  void _toastError(String message) => ToastService.show(
        title: 'Action failed',
        message: message,
        type: ToastType.error,
      );

  Future<void> _handleAction(IdentityRequest request, bool isApprove) async {
    final actionName = isApprove ? 'Approve' : 'Reject';
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: '$actionName Identity',
      message:
          'Are you sure you want to ${actionName.toLowerCase()} the identity verification for ${request.name}?',
      confirmLabel: actionName,
      confirmButtonColor: isApprove ? AppColors.kSuccess : AppColors.kDanger,
    );

    if (confirmed != true || !mounted) return;

    await _applyStatus(
      request,
      isApprove ? 'verified' : 'rejected',
      successTitle: 'Identity ${isApprove ? 'Approved' : 'Rejected'}',
      toastType: isApprove ? ToastType.success : ToastType.error,
    );
  }

  /// Puts a decided request back in the queue. The server has no way to erase
  /// a KYC record, so this is the closest thing to undoing a decision.
  Future<void> _handleReopen(IdentityRequest request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Reopen Identity',
      message:
          'Move ${request.name} back to the pending queue for another review?',
      confirmLabel: 'Reopen',
      confirmButtonColor: AppColors.kPrimary,
    );
    if (confirmed != true || !mounted) return;

    await _applyStatus(
      request,
      'pending',
      successTitle: 'Identity Reopened',
      toastType: ToastType.info,
    );
  }

  Future<void> _openReview(IdentityRequest request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdentityReviewScreen(request: request),
      ),
    );

    if (result is! bool || !mounted) return;
    await _applyStatus(
      request,
      result ? 'verified' : 'rejected',
      successTitle: result ? 'Identity Approved' : 'Identity Rejected',
      toastType: result ? ToastType.success : ToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        if (_error == null) ...[
          _buildFilterTabs(),
          const SizedBox(height: 20),
        ],
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(child: AppLoader()),
          )
        else if (_error != null)
          _buildErrorState(_error!)
        else if (_visible.isEmpty)
          _buildEmptyState()
        else
          ..._visible.map(_buildVerificationCard),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.goldColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IDENTITY VERIFICATION',
                style: TextStyle(
                  color: AppColors.kPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'REVIEW AND MANAGE USER IDENTITY SUBMISSIONS',
                style: TextStyle(
                  color: AppColors.kTextMuted.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loading ? null : _loadRequests,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.kPrimary),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: IdentityFilter.values.map((filter) {
          final isActive = filter == _filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _filter = filter),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.kPrimary : AppColors.kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppColors.kPrimary : AppColors.kBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0,
                        color: isActive ? Colors.white : AppColors.kPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.goldColor.withOpacity(0.25)
                            : AppColors.kPrimary.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_countFor(filter)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: isActive
                              ? AppColors.goldColor
                              : AppColors.kTextMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// PENDING / VERIFIED / REJECTED, coloured the way the rest of the app
  /// signals those states.
  Widget _buildStatusPill(IdentityRequest request) {
    final Color colour = request.isVerified
        ? AppColors.kSuccess
        : request.isRejected
            ? AppColors.kDanger
            : AppColors.goldColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colour.withOpacity(0.35)),
      ),
      child: Text(
        request.statusLabel,
        style: TextStyle(
          color: colour,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildVerificationCard(IdentityRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.kPrimary.withOpacity(0.1)),
                ),
                alignment: Alignment.center,
                child: Text(
                  request.initial,
                  style: const TextStyle(
                    color: AppColors.kPrimary,
                    fontSize: 22,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.name,
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
                        ),
                        const SizedBox(width: 8),
                        _buildStatusPill(request),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 12, color: AppColors.kTextMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            request.email.toLowerCase(),
                            style: const TextStyle(
                              color: AppColors.kTextMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (request.customerId.isNotEmpty) ...[
                          Text(
                            request.customerId,
                            style: const TextStyle(
                              color: AppColors.kTextMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Icon(
                          request.hasDocument
                              ? Icons.attach_file_rounded
                              : Icons.block_outlined,
                          size: 11,
                          color: request.hasDocument
                              ? AppColors.kSuccess
                              : AppColors.kTextMuted.withOpacity(0.6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          request.hasDocument ? 'DOCUMENT' : 'NO DOCUMENT',
                          style: TextStyle(
                            color: request.hasDocument
                                ? AppColors.kSuccess
                                : AppColors.kTextMuted.withOpacity(0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => _openReview(request),
                    icon: const Icon(Icons.description_outlined, size: 22),
                    label: const Text(
                      'REVIEW DOCS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kPrimary,
                      side: BorderSide(
                        color: AppColors.kBorder.withOpacity(0.8),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_busy.contains(request.id))
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              // A decided request offers the reverse action instead, so a
              // mistaken approval or rejection can be put back in the queue.
              else if (!request.isPending)
                SizedBox(
                  width: 42,
                  height: 42,
                  child: _buildIconButton(
                    icon: Icons.undo_rounded,
                    iconColor: AppColors.kPrimary,
                    bgColor: AppColors.kPrimary.withOpacity(0.08),
                    tooltip: 'Reopen for review',
                    onTap: () => _handleReopen(request),
                  ),
                )
              else ...[
                SizedBox(
                  width: 42,
                  height: 42,
                  child: _buildIconButton(
                    icon: Icons.check_rounded,
                    iconColor: Colors.white,
                    bgColor: AppColors.kPrimary,
                    tooltip: 'Approve',
                    onTap: () => _handleAction(request, true),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  height: 42,
                  child: _buildIconButton(
                    icon: Icons.close_rounded,
                    iconColor: AppColors.kDanger,
                    bgColor: AppColors.kDanger.withOpacity(0.1),
                    tooltip: 'Reject',
                    onTap: () => _handleAction(request, false),
                  ),
                ),
              ],
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(child: Icon(icon, size: 25, color: iconColor)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 80, color: AppColors.kTextMuted.withOpacity(0.15)),
          const SizedBox(height: 24),
          Text(
            _filter == IdentityFilter.all
                ? 'NO IDENTITY RECORDS'
                : 'NO ${_filter.label} VERIFICATIONS',
            style: const TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _filter == IdentityFilter.pending
                ? 'All submitted identities have been processed.'
                : 'Nothing in this queue right now.',
            style: TextStyle(
              color: AppColors.kTextMuted.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kDanger.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.kDanger.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadRequests,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
