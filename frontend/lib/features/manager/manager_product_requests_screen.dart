import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/models/investment_model.dart' show formatInr;
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/investment_report_model.dart';
import '../../services/investment_report_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

// Breakpoints shared by the screen and its cards.
const double _kTabletBreakpoint = 600;
const double _kDesktopBreakpoint = 1024;

// ============================================================================
// MAIN SCREEN
// ============================================================================
/// Manager view of pending gold/asset purchase requests
/// (cashback_cycles with status == 'pending', via admin/investments.php).
class ProductRequestsScreenManager extends StatefulWidget {
  const ProductRequestsScreenManager({super.key});

  @override
  State<ProductRequestsScreenManager> createState() =>
      _ProductRequestsScreenManagerState();
}

class _ProductRequestsScreenManagerState
    extends State<ProductRequestsScreenManager> {
  final InvestmentService _service = InvestmentService();
  final TextEditingController _searchController = TextEditingController();

  List<Investment> _allRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _query = '';

  // ids currently being approved/rejected, so we can disable just those buttons
  final Set<int> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _service.fetchPendingInvestments();
      if (!mounted) return;
      setState(() {
        _allRequests = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<Investment> get _filteredRequests {
    if (_query.isEmpty) return _allRequests;
    return _allRequests.where((r) {
      return r.userName.toLowerCase().contains(_query) ||
          r.userEmail.toLowerCase().contains(_query) ||
          _assetLabel(r).toLowerCase().contains(_query);
    }).toList();
  }

  // --- Action Handlers ---
  Future<void> _handleApprove(Investment request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'APPROVE PURCHASE',
      message:
          'Are you sure you want to approve the purchase request for ${request.userName}?',
      confirmLabel: 'APPROVE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kPrimary,
    );
    if (confirmed != true) return;
    await _submitDecision(request, approve: true);
  }

  Future<void> _handleReject(Investment request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REJECT PURCHASE',
      message:
          'Are you sure you want to reject the purchase request for ${request.userName}?',
      confirmLabel: 'REJECT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true) return;
    await _submitDecision(request, approve: false);
  }

  Future<void> _submitDecision(Investment request,
      {required bool approve}) async {
    setState(() => _busyIds.add(request.cycleId));

    try {
      await _service.decideInvestment(
        cycleId: request.cycleId,
        approve: approve,
      );
      if (!mounted) return;
      setState(() {
        _busyIds.remove(request.cycleId);
        _allRequests.removeWhere((r) => r.cycleId == request.cycleId);
      });
      ToastService.show(
        title: approve ? 'Purchase Approved' : 'Purchase Rejected',
        message: approve
            ? 'Request for ${request.userName} has been processed.'
            : 'Request for ${request.userName} has been declined.',
        type: approve ? ToastType.success : ToastType.info,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyIds.remove(request.cycleId));
      ToastService.show(
        title: 'Something went wrong',
        message: e.toString(),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= _kTabletBreakpoint;
    final outerPadding = isTablet ? 32.0 : 16.0;
    final panelPadding = isTablet ? 40.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadRequests(silent: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(outerPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. Search Bar ---
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.kBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search customers, assets...',
                          hintStyle: TextStyle(
                              color: AppColors.kTextMuted, fontSize: 14),
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.kTextMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 32 : 24),

                    // --- 2. Panel: title + requests ---
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(panelPadding),
                      decoration: BoxDecoration(
                        color: AppColors.kSurface,
                        borderRadius: BorderRadius.circular(isTablet ? 40 : 28),
                        border: Border.all(color: AppColors.kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PENDING PURCHASE REQUESTS',
                            style: TextStyle(
                              fontSize: isTablet ? 28 : 20,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: AppColors.kPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildBody(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: AppLoader()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.wifi_off, color: AppColors.kTextMuted, size: 32),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _loadRequests(),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final requests = _filteredRequests;

    if (requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text(
            'NO PENDING REQUESTS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.kTextMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    }

    // 1 column on phones, 2 on tablets, 3 on wide screens.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final screenW = MediaQuery.of(context).size.width;
        final columns = screenW >= _kDesktopBreakpoint
            ? 3
            : screenW >= _kTabletBreakpoint
                ? 2
                : 1;
        const spacing = 20.0;
        final cardWidth = (maxW - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final request in requests)
              SizedBox(
                width: cardWidth,
                child: _RequestCard(
                  request: request,
                  compact: screenW < _kTabletBreakpoint,
                  isBusy: _busyIds.contains(request.cycleId),
                  onApprove: () => _handleApprove(request),
                  onReject: () => _handleReject(request),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// DISPLAY HELPERS
// ============================================================================
String _assetLabel(Investment r) {
  final name = r.productName?.trim();
  if (name != null && name.isNotEmpty) return name.toUpperCase();
  return r.assetType == 'silver' ? 'SILVER ASSET' : 'GOLD ASSET';
}

String _quantityLabel(Investment r) {
  final w = r.weight ?? 0;
  return w > 0 ? '${w.toStringAsFixed(3)} GRAMS' : '1 UNIT';
}

double _valuation(Investment r) {
  if (r.totalValue > 0) return r.totalValue;
  if (r.cashbackEligibleAmount > 0) return r.cashbackEligibleAmount;
  return r.productAmount ?? 0;
}

/// Monthly installment from the API, falling back to eligible / 10 months
/// (the default plan length) if an older backend doesn't send it.
double _monthly(Investment r) {
  if (r.monthlyInstallment > 0) return r.monthlyInstallment;
  final base =
      r.cashbackEligibleAmount > 0 ? r.cashbackEligibleAmount : _valuation(r);
  return base / 10;
}

// ============================================================================
// REQUEST CARD
// ============================================================================
class _RequestCard extends StatelessWidget {
  final Investment request;
  final bool compact;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.compact,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  static const _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    color: AppColors.kTextMuted,
    letterSpacing: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamically determine layout properties based on the card's actual width
        final isWide = constraints.maxWidth > 400;
        final pad = isWide ? 32.0 : 20.0;
        final radius = isWide ? 36.0 : 24.0;
        final avatarSize = isWide ? 64.0 : 52.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.kBackground,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.kBorder.withOpacity(0.6)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Customer + Asset Details ---
              Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 0.75),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CUSTOMER', style: _labelStyle),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            color: AppColors.kPrimary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            request.initial,
                            style: TextStyle(
                              color: AppColors.kSurface,
                              fontSize: isWide ? 22 : 20,
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
                                request.userName.isEmpty
                                    ? 'UNKNOWN'
                                    : request.userName.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.kPrimary,
                                  fontSize: isWide ? 18 : 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (request.userEmail.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  request.userEmail.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.kTextMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isWide ? 32 : 24),
                    const Text('ASSET DETAILS', style: _labelStyle),
                    const SizedBox(height: 12),
                    Text(
                      _assetLabel(request),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.kPrimary,
                        fontSize: isWide ? 20 : 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _quantityLabel(request),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.goldColor,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: isWide ? 32 : 24),
                    const Text('VALUATION', style: _labelStyle),
                  ],
                ),
              ),

              // --- Valuation + Actions (white, gold-edged block) ---
              Container(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: AppColors.goldColor.withOpacity(0.35),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatInr(_valuation(request)),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.kPrimary,
                          fontSize: isWide ? 30 : 26,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatInr(_monthly(request))}/MONTH',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.goldColor,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: isWide ? 36 : 28),
                    
                    // Buttons adapt slightly based on width
                    Row(
                      children: [
                        Expanded(
                          flex: isWide ? 3 : 1,
                          child: ElevatedButton(
                            onPressed: isBusy ? null : onApprove,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kPrimary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.kPrimary.withOpacity(0.6),
                              padding: EdgeInsets.symmetric(
                                  vertical: isWide ? 22 : 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              elevation: 6,
                              shadowColor: AppColors.kPrimary.withOpacity(0.25),
                            ),
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
                                    'APPROVE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: isWide ? 16 : 14),
                        Expanded(
                          flex: isWide ? 2 : 1,
                          child: OutlinedButton(
                            onPressed: isBusy ? null : onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.kTextMuted,
                              backgroundColor: AppColors.kSurface,
                              side: const BorderSide(
                                  color: AppColors.kBorder, width: 1.5),
                              padding: EdgeInsets.symmetric(
                                  vertical: isWide ? 22 : 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text(
                              'REJECT',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: pad * 0.75),
            ],
          ),
        );
      },
    );
  }
}