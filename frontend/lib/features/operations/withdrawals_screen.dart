import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/withdrawal_models.dart';
import '../../services/withdrawal_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class WithdrawalsScreen extends StatefulWidget {
  const WithdrawalsScreen({super.key});

  @override
  State<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends State<WithdrawalsScreen> {
  final _service = WithdrawalsService();

  List<WithdrawalRequest> _requests = [];
  bool _isLoading = true;
  bool _isProcessingYield = false;
  String? _errorMessage;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final requests = await _service.fetchWithdrawals();
      setState(() => _requests = requests);
    } on WithdrawalsException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message: "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );
    if (confirmed != true) return;

    setState(() => _isProcessingYield = true);
    try {
      final uri = ApiConfig.endpoint(AdminEndpoints.processMonthlyYield);
      final response = await http.post(uri).timeout(ApiConfig.timeout);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final success = body['status'] == 'success';
      ToastService.show(
        title: success ? 'Success' : 'Failed',
        message: body['message']?.toString() ?? 'Monthly yield processed successfully.',
        type: success ? ToastType.success : ToastType.error,
      );
    } catch (e) {
      ToastService.show(title: 'Failed', message: 'Could not process yield: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isProcessingYield = false);
    }
  }

  Future<void> _handleApprove(WithdrawalRequest request) async {
    final txnController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('APPROVE WITHDRAWAL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approve ₹${request.amount.toStringAsFixed(2)} for ${request.userName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: txnController,
              decoration: const InputDecoration(
                labelText: 'Transaction / UTR Reference (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            child: const Text('APPROVE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busyIds.add(request.id));
    try {
      await _service.approve(request.id, transactionId: txnController.text.trim());
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      ToastService.show(title: 'Approved', message: 'Withdrawal for ${request.userName} approved.', type: ToastType.success);
    } on WithdrawalsException catch (e) {
      ToastService.show(title: 'Approve Failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  Future<void> _handleReject(WithdrawalRequest request) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REJECT WITHDRAWAL',
      message: 'Reject this ₹${request.amount.toStringAsFixed(2)} request from ${request.userName}? '
          'The locked capital will be refunded back to their wallet.',
      confirmLabel: 'REJECT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF3B82F6),
    );
    if (confirmed != true) return;

    setState(() => _busyIds.add(request.id));
    try {
      await _service.reject(request.id);
      if (!mounted) return;
      setState(() => _requests.removeWhere((r) => r.id == request.id));
      ToastService.show(title: 'Rejected', message: 'Withdrawal rejected and capital refunded.', type: ToastType.info);
    } on WithdrawalsException catch (e) {
      ToastService.show(title: 'Reject Failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  String _formatCurrency(double value) {
    final rounded = value.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      buffer.write(str[i]);
      if (posFromEnd > 1 && posFromEnd <= 3) continue;
      if (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0) buffer.write(',');
    }
    return '₹$buffer';
  }

  int get _pendingCount => _requests.where((r) => r.isPending).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
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
                      hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  _buildErrorBanner(_errorMessage!),
                  const SizedBox(height: 16),
                ],

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessingYield ? null : _handleProcessYield,
                    icon: _isProcessingYield
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bolt, size: 16),
                    label: Text(
                      _isProcessingYield ? 'PROCESSING...' : 'PROCESS MONTHLY YIELD',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 4,
                      shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            bool isMobile = constraints.maxWidth < 600;

                            Widget titleSection = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PAYOUT LIST',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'AUTHORIZED LIQUIDATION OF INVESTOR CAPITAL RESERVES',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.9), letterSpacing: 1),
                                ),
                              ],
                            );

                            Widget badgeSection = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 6, color: Color(0xFF3B82F6)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_pendingCount AWAITING LIQUIDATION',
                                    style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            );

                            if (isMobile) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [titleSection, const SizedBox(height: 16), badgeSection],
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Expanded(child: titleSection), badgeSection],
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.kBorder),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 120),
                          child: Center(child: AppLoader()),
                        )
                      else if (_requests.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
                          alignment: Alignment.center,
                          child: const Text(
                            'INSTITUTIONAL PAYOUT QUEUE IS CURRENTLY EMPTY',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1), letterSpacing: 2),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                            child: DataTable(
                              columnSpacing: 48,
                              headingRowHeight: 56,
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              dividerThickness: 0,
                              headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 11, letterSpacing: 2),
                              columns: const [
                                DataColumn(label: Text('CUSTOMER')),
                                DataColumn(label: Text('CHANNEL')),
                                DataColumn(label: Text('QUANTUM (₹)')),
                                DataColumn(label: Text('STATUS')),
                                DataColumn(label: Text('ACTIONS')),
                              ],
                              rows: _requests.map((r) => _buildRow(r)).toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13))),
          IconButton(icon: const Icon(Icons.close, size: 18, color: Color(0xFFB91C1C)), onPressed: () => setState(() => _errorMessage = null)),
        ],
      ),
    );
  }

  DataRow _buildRow(WithdrawalRequest r) {
    Color statusColor;
    switch (r.status) {
      case 'approved':
        statusColor = const Color(0xFF16A34A);
        break;
      case 'rejected':
        statusColor = const Color(0xFFB91C1C);
        break;
      default:
        statusColor = const Color(0xFFD97706);
    }
    final isBusy = _busyIds.contains(r.id);

    return DataRow(cells: [
      DataCell(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13)),
            Text(r.userEmail, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          ],
        ),
      ),
      DataCell(Text(r.paymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      DataCell(Text(_formatCurrency(r.amount), style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 14))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(r.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        ),
      ),
      DataCell(
        r.isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: isBusy ? null : () => _handleApprove(r),
                    child: isBusy
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('APPROVE', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                  TextButton(
                    onPressed: isBusy ? null : () => _handleReject(r),
                    child: const Text('REJECT', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ],
              )
            : Text(
                r.transactionId ?? '—',
                style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted),
              ),
      ),
    ]);
  }
}