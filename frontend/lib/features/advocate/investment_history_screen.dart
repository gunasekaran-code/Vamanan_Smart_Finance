import 'package:flutter/material.dart';
import 'package:frontend/models/investment_history_model.dart';
import 'package:frontend/services/investment_history_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class InvestmentHistoryScreen extends StatefulWidget {
  /// Optional user scope. When supplied (e.g. opened from the investor wallet
  /// list), the audit table only shows cycles belonging to this user until the
  /// scope banner is dismissed.
  final String? userId;
  final String? userName;

  const InvestmentHistoryScreen({super.key, this.userId, this.userName});

  @override
  State<InvestmentHistoryScreen> createState() =>
      _InvestmentHistoryScreenState();
}

class _InvestmentHistoryScreenState extends State<InvestmentHistoryScreen> {
  final InvestmentHistoryService _service = InvestmentHistoryService.instance;

  List<InvestmentHistoryRecord> _records = [];
  bool _loading = true;
  String? _error;
  final Set<int> _deletingIds = {};
  String _query = '';

  /// Active only while a userId was passed in and the user has not cleared it.
  bool _userScoped = false;

  // Column widths for the horizontal scrolling table
  final double _colNodeWidth = 120.0;
  final double _colCustomerWidth = 220.0;
  final double _colPortfolioWidth = 160.0;
  final double _colCapitalWidth = 160.0;
  final double _colUtrWidth = 150.0;
  final double _colStatusWidth = 110.0;
  final double _colActionWidth = 70.0;

  @override
  void initState() {
    super.initState();
    _userScoped = (widget.userId ?? '').trim().isNotEmpty;
    _loadHistory();
  }

  // --------------------------------------------------------------------------
  // DATA LOADING
  // --------------------------------------------------------------------------
  Future<void> _loadHistory({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final response = await _service.fetchHistory();
    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _records = response.data!;
        _loading = false;
        _error = null;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.message ?? 'Unable to load audit history.';
      });
    }
  }

  List<InvestmentHistoryRecord> get _filteredRecords {
    final scoped = _userScoped
        ? _records
            .where((r) => r.userId.toString() == widget.userId!.trim())
            .toList()
        : _records;
    if (_query.trim().isEmpty) return scoped;
    final q = _query.trim().toLowerCase();
    return scoped.where((r) {
      return r.customerName.toLowerCase().contains(q) ||
          r.customerEmail.toLowerCase().contains(q) ||
          r.utrDisplay.toLowerCase().contains(q) ||
          r.assetTypeDisplay.toLowerCase().contains(q) ||
          r.status.contains(q);
    }).toList();
  }

  // --------------------------------------------------------------------------
  // RECEIPT VIEWER
  // --------------------------------------------------------------------------
  void _openReceiptViewer(InvestmentHistoryRecord record) {
    final receiptUrl = record.receiptImageUrl;
    if (receiptUrl == null) {
      ToastService.show(
        title: 'No Receipt Available',
        message: 'No payment receipt was uploaded for this record.',
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
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
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
  // DELETE (CRUD — Delete)
  // --------------------------------------------------------------------------
  Future<void> _handleDeleteRecord(InvestmentHistoryRecord record) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DELETE AUDIT RECORD',
      message:
          'Are you sure you want to remove the history record for ${record.customerName}?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(record.id));

    final response = await _service.deleteRecord(record.id);

    if (!mounted) return;
    setState(() => _deletingIds.remove(record.id));

    if (response.success) {
      setState(() => _records.removeWhere((item) => item.id == record.id));
      ToastService.show(
        title: 'Record Removed',
        message: 'Successfully deleted history log for ${record.customerName}',
        type: ToastType.success,
      );
    } else {
      ToastService.show(
        title: 'Delete Failed',
        message: response.message ?? 'Could not delete this record.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: RefreshIndicator(
        color: AppColors.kPrimary,
        onRefresh: () => _loadHistory(silent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle:
                        TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.kTextMuted, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Scope banner — shown when this screen was opened for one
              // investor from the wallet list.
              if (_userScoped) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined,
                          size: 16, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SHOWING PAYOUTS FOR ${(widget.userName ?? 'THIS INVESTOR').toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E3A8A),
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _userScoped = false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'SHOW ALL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF3B82F6),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Processed Status Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BA2CE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'PROCESSED INVESTMENT RECORDS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INVESTMENT\nAUDIT HISTORY',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: AppColors.kPrimary,
                            letterSpacing: 0.5,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'INSTITUTIONAL LOG OF ALL\nPROCESSED GOLD ASSET\nACQUISITIONS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kTextMuted,
                            letterSpacing: 0.8,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_records.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.kTextDark,
                          ),
                        ),
                        const Text(
                          'RECORDS\nDETECTED',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kTextDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildBody(filtered),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<InvestmentHistoryRecord> filtered) {
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
                onPressed: () => _loadHistory(), child: const Text('Retry')),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: _colNodeWidth +
                  _colCustomerWidth +
                  _colPortfolioWidth +
                  _colCapitalWidth +
                  _colUtrWidth +
                  _colStatusWidth +
                  _colActionWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableHeader(),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        _records.isEmpty
                            ? 'No audit records found.'
                            : 'No records match your search.',
                        style: const TextStyle(color: AppColors.kTextMuted),
                      ),
                    ),
                  )
                else
                  ...filtered.map((record) => _buildTableRow(record)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          _headerCell('PROCESSING\nNODE', _colNodeWidth),
          _headerCell('CUSTOMER', _colCustomerWidth),
          _headerCell('PORTFOLIO\nINSIGHT', _colPortfolioWidth),
          _headerCell('CAPITAL MATRIX', _colCapitalWidth),
          _headerCell('UTR /\nREFERENCE', _colUtrWidth),
          _headerCell('STATUS CODE', _colStatusWidth),
          _headerCell('ACTION', _colActionWidth),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          color: AppColors.kTextMuted,
          letterSpacing: 1.0,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildTableRow(InvestmentHistoryRecord record) {
    final isDeleting = _deletingIds.contains(record.id);
    final statusColors = _statusColors(record.status);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Processing Node
          SizedBox(
            width: _colNodeWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.processDateDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.processTimeDisplay,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // 2. Customer
          SizedBox(
            width: _colCustomerWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.customerEmail,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kTextDark,
                  ),
                ),
              ],
            ),
          ),

          // 3. Portfolio Insight
          SizedBox(
            width: _colPortfolioWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.assetTypeDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined,
                        size: 12, color: Color(0xFFC59B27)),
                    const SizedBox(width: 4),
                    Text(
                      record.weightDisplay,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFC59B27),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Capital Matrix
          SizedBox(
            width: _colCapitalWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.capitalAmountDisplay,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.dailyAmountDisplay,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFC59B27),
                  ),
                ),
              ],
            ),
          ),

          // 5. UTR / Reference
          SizedBox(
            width: _colUtrWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.paymentMethodDisplay,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFC59B27),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.utrDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _openReceiptViewer(record),
                  child: const Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 12, color: Color(0xFFC59B27)),
                      SizedBox(width: 4),
                      Text(
                        'VIEW RECEIPT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC59B27),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 6. Status Code
          SizedBox(
            width: _colStatusWidth,
            child: Align(
              alignment: Alignment.centerLeft, // Prevents badge stretching
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColors.bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusColors.icon, size: 14, color: statusColors.fg),
                    const SizedBox(width: 6),
                    Text(
                      record.statusDisplay,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColors.fg,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 7. Action
          SizedBox(
            width: _colActionWidth,
            child: Align(
              alignment: Alignment
                  .center, // Centers the button to add spacing from the status badge
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: isDeleting
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFF6366F1)),
                        onPressed: () => _handleDeleteRecord(record),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(10),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusColors _statusColors(String status) {
    switch (status) {
      case 'active':
        return _StatusColors(
          bg: const Color(0xFFFFF9E6),
          border: const Color(0xFFFBE4A0),
          fg: const Color(0xFFC59B27),
          icon: Icons.check_circle_outline,
        );
      case 'rejected':
        return _StatusColors(
          bg: const Color(0xFFFEF2F2),
          border: const Color(0xFFFECACA),
          fg: const Color(0xFFDC2626),
          icon: Icons.cancel_outlined,
        );
      case 'completed':
        return _StatusColors(
          bg: const Color(0xFFF0F7FF),
          border: const Color(0xFFBFDBFE),
          fg: const Color(0xFF1D4ED8),
          icon: Icons.verified_outlined,
        );
      default:
        return _StatusColors(
          bg: const Color(0xFFF1F5F9),
          border: const Color(0xFFE2E8F0),
          fg: AppColors.kTextMuted,
          icon: Icons.help_outline,
        );
    }
  }
}

class _StatusColors {
  final Color bg;
  final Color border;
  final Color fg;
  final IconData icon;

  const _StatusColors({
    required this.bg,
    required this.border,
    required this.fg,
    required this.icon,
  });
}
