import 'package:flutter/material.dart';
import 'package:frontend/models/investment_model.dart';
import 'package:frontend/services/investment_service.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final InvestmentService _service = InvestmentService.instance;

  List<InvestmentRequest> _requests = [];
  bool _loading = true;
  String? _error;
  final Set<int> _actioningIds = {}; // ids currently being approved/rejected

  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  // --------------------------------------------------------------------------
  // DATA LOADING
  // --------------------------------------------------------------------------
  Future<void> _loadPending({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final response = await _service.fetchPending();

    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _requests = response.data!;
        _loading = false;
        _error = null;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.message ?? 'Unable to load investment requests.';
      });
    }
  }

  List<InvestmentRequest> get _filteredRequests {
    if (_query.trim().isEmpty) return _requests;
    final q = _query.trim().toLowerCase();
    return _requests.where((r) {
      return r.userName.toLowerCase().contains(q) ||
          r.userEmail.toLowerCase().contains(q) ||
          r.transactionId.toLowerCase().contains(q) ||
          r.displayAssetLabel.toLowerCase().contains(q);
    }).toList();
  }

  // --------------------------------------------------------------------------
  // RECEIPT VIEWER MODAL
  // --------------------------------------------------------------------------
  void _openReceiptViewer(BuildContext context, InvestmentRequest request) {
    final receiptUrl = request.receiptImageUrl;
    if (receiptUrl == null) {
      ToastService.show(
        title: 'No Receipt Available',
        message: 'This request has no uploaded payment receipt.',
        type: ToastType.error,
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    receiptUrl,
                    fit: BoxFit.contain,
                    // Upload files are served without CORS headers, so on web load
                    // them through an <img> element, which the browser doesn't block.
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.kPrimary),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Unable to load receipt image.',
                          style: TextStyle(color: AppColors.kTextMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // CRUD ACTION HANDLERS (approve / reject against the real database)
  // --------------------------------------------------------------------------
  Future<void> _handleAuthorize(InvestmentRequest request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'AUTHORIZE ACTIVATION',
      message: 'Are you sure you want to APPROVE this investment request?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Okay',
      confirmButtonColor: AppColors.kPrimary,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actioningIds.add(request.id));

    final response = await _service.approve(request.id);

    if (!mounted) return;
    setState(() => _actioningIds.remove(request.id));

    if (response.success) {
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      ToastService.show(
        title: 'Investment Approved',
        message: 'Activated gold request for ${request.userName}',
        type: ToastType.success,
      );
    } else {
      ToastService.show(
        title: 'Approval Failed',
        message: response.message ?? 'Could not approve this request.',
        type: ToastType.error,
      );
    }
  }

  Future<void> _handleReject(InvestmentRequest request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REJECT ASSET REQUEST',
      message: 'Are you sure you want to REJECT this investment request?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Okay',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actioningIds.add(request.id));

    final response = await _service.reject(request.id);

    if (!mounted) return;
    setState(() => _actioningIds.remove(request.id));

    if (response.success) {
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      ToastService.show(
        title: 'Request Rejected',
        message: 'Rejected asset submission for ${request.userName}',
        type: ToastType.error,
      );
    } else {
      ToastService.show(
        title: 'Rejection Failed',
        message: response.message ?? 'Could not reject this request.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRequests;

    return Container(
      color: const Color(0xFFF4F6FB),
      child: RefreshIndicator(
        color: AppColors.kPrimary,
        onRefresh: () => _loadPending(silent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle:
                        TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Processor Status Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BA2CE),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_outlined,
                        color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'PROCESSOR ONLINE • 24/7 AUTO VERIFY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Header Title Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PENDING GOLD REQUESTS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: AppColors.kPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'REVIEW AND APPROVE CUSTOMER INVESTMENT SUBMISSIONS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_requests.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC59B27),
                          ),
                        ),
                        const Text(
                          'PENDING',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC59B27),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildBody(filtered),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<InvestmentRequest> filtered) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: AppLoader()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.kDanger, size: 32),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _loadPending(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            _requests.isEmpty
                ? 'No pending investment requests.'
                : 'No requests match your search.',
            style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final request = filtered[index];
        final isBusy = _actioningIds.contains(request.id);
        return _InvestmentCard(
          request: request,
          isBusy: isBusy,
          onVerifyReceipt: () => _openReceiptViewer(context, request),
          onAuthorize: () => _handleAuthorize(request),
          onReject: () => _handleReject(request),
        );
      },
    );
  }
}

// ============================================================================
// INVESTMENT CARD COMPONENT
// ============================================================================
class _InvestmentCard extends StatelessWidget {
  final InvestmentRequest request;
  final bool isBusy;
  final VoidCallback onVerifyReceipt;
  final VoidCallback onAuthorize;
  final VoidCallback onReject;

  const _InvestmentCard({
    required this.request,
    required this.isBusy,
    required this.onVerifyReceipt,
    required this.onAuthorize,
    required this.onReject,
  });

  static const Color _goldColor = Color(0xFFC59B27);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdentitySection(),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAssetSection()),
              const SizedBox(width: 16),
              Expanded(child: _buildFinancialSection()),
            ],
          ),
          const SizedBox(height: 20),
          _buildPaymentSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _buildFooterTags(),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('INVESTOR IDENTITY'),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.kPrimary,
              child: Text(
                request.userName.isNotEmpty
                    ? request.userName.characters.first.toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.userName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.userEmail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.kTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('ENTITLED ASSET'),
        const SizedBox(height: 8),
        Text(
          request.displayAssetLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.kPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.workspace_premium_outlined,
                size: 14, color: _goldColor),
            const SizedBox(width: 4),
            Text(
              request.weightDisplay,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _goldColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('FINANCIAL MATRIX'),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            request.amountDisplay,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.kPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          request.dailyPayoutDisplay,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _goldColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('PAYMENT MODE'),
                const SizedBox(height: 6),
                const Text(
                  'BANK TRANSFER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _goldColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'UTR: ${request.utrDisplay}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kPrimary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onVerifyReceipt,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _goldColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.crop_free_rounded, size: 14, color: _goldColor),
                  SizedBox(width: 6),
                  Text(
                    'RECEIPT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _goldColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: isBusy ? null : onAuthorize,
            child: isBusy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'AUTHORIZE ACTIVATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kTextMuted,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: isBusy ? null : onReject,
            child: const Text(
              'REJECT ASSET REQUEST',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 14, color: AppColors.kTextMuted),
            const SizedBox(width: 6),
            Text(
              'SUBMITTED: ${request.submittedTimeDisplay}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusBadge(
              'AWAITING VERIFICATION',
              const Color(0xFFFFFDF5),
              _goldColor,
              Icons.hourglass_top_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.kTextMuted,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildStatusBadge(
      String text, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
