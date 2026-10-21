import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/product_request_model.dart';
import '../../services/product_request_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class ProductRequestsScreen extends StatefulWidget {
  const ProductRequestsScreen({super.key});

  @override
  State<ProductRequestsScreen> createState() => _ProductRequestsScreenState();
}

class _ProductRequestsScreenState extends State<ProductRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<ProductRequest> _requests = [];

  List<ProductRequest> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _requests;
    return _requests.where((r) =>
        r.customerName.toLowerCase().contains(q) ||
        r.customerId.toLowerCase().contains(q) ||
        r.productName.toLowerCase().contains(q)).toList();
  }

  int get _pendingCount => _requests.where((r) => r.status == 'pending').length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ProductRequestService.instance.fetchAll();
      if (!mounted) return;
      setState(() {
        _requests = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
      ToastService.show(
        title: 'Yield Processed',
        message: 'Monthly cashback installments have been successfully credited.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _updateStatus(ProductRequest r, String newStatus, {String label = ''}) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: label.isNotEmpty ? label : 'Update Request',
      message: 'Mark ${r.productName} for ${r.customerName} as $newStatus?',
      confirmLabel: 'CONFIRM',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );
    if (confirmed != true) return;

    try {
      await ProductRequestService.instance.updateStatus(id: r.id, status: newStatus);
      await _load();
      ToastService.show(title: 'Request Updated', message: 'Status set to $newStatus.', type: ToastType.success);
    } catch (e) {
      ToastService.show(title: 'Update Failed', message: e.toString(), type: ToastType.error);
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Reduced outer padding from 24 to 16 for better mobile spacing
            padding: const EdgeInsets.all(16.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search users, orders, assets...',
                      hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
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
                    label: const Text('PROCESS MONTHLY YIELD',
                        style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 4,
                      shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // Reduced radius slightly for mobile screens
                    borderRadius: BorderRadius.circular(24), 
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reduced inner padding from 32 to 20
                      Padding(
                        padding: const EdgeInsets.all(20.0), 
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. ADDED EXPANDED HERE to force text to wrap instead of overflowing
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PRODUCT REQUESTS',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                                  const SizedBox(height: 6),
                                  Text(
                                    'CUSTOMER-SUBMITTED PRODUCT REQUESTS AWAITING REVIEW',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        color: const Color(0xFF94A3B8).withOpacity(0.8),
                                        letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 2. Shortened the text in the badge slightly to save horizontal space
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text('$_pendingCount PENDING',
                                      style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: AppColors.kBorder),
                      if (_loading)
                        const Padding(padding: EdgeInsets.all(40), child: Center(child: AppLoader()))
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        )
                      else if (_filtered.isEmpty)
                        const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No product requests found.')))
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: DataTable(
                              columnSpacing: 32, // Reduced spacing for better mobile fit
                              headingRowHeight: 56,
                              dataRowMinHeight: 100,
                              dataRowMaxHeight: 120,
                              dividerThickness: 0,
                              headingTextStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                              columns: const [
                                DataColumn(label: Text('CUSTOMER')),
                                DataColumn(label: Text('REQUESTED PRODUCT')),
                                DataColumn(label: Text('SPECS')),
                                DataColumn(label: Text('STATUS')),
                                DataColumn(label: Text('ACTIONS')),
                              ],
                              rows: _filtered.map((request) {
                                return DataRow(cells: [
                                  DataCell(Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
                                        alignment: Alignment.center,
                                        child: Text(
                                          request.customerName.isNotEmpty ? request.customerName.substring(0, 1).toUpperCase() : '?',
                                          style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(request.customerName,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text(request.customerId,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), fontSize: 11)),
                                          const SizedBox(height: 2),
                                          Text(request.customerEmail, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  )),
                                  DataCell(Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(request.productName,
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 14)),
                                      if (request.modelLabel.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(request.modelLabel,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), fontSize: 11)),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(request.category,
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 10)),
                                    ],
                                  )),
                                  DataCell(Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('QTY ${request.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Text('${request.dateDay}\n${request.dateMonth}',
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 10, height: 1.1)),
                                        ],
                                      ),
                                    ],
                                  )),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _statusBg(request.status),
                                      border: Border.all(color: _statusBorder(request.status)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(request.statusLabel,
                                        style: TextStyle(color: _statusFg(request.status), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                                  )),
                                  DataCell(_buildActions(request)),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(ProductRequest r) {
    switch (r.status) {
      case 'pending':
      case 'reviewing':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _updateStatus(r, 'approved', label: 'Approve Request'),
              child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
            ),
            TextButton(
              onPressed: () => _updateStatus(r, 'rejected', label: 'Reject Request'),
              child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
            ),
          ],
        );
      case 'approved':
        return TextButton(
          onPressed: () => _updateStatus(r, 'fulfilled', label: 'Mark Fulfilled'),
          child: const Text('FULFILL', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
        );
      default:
        return Text(r.statusLabel,
            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 12));
    }
  }

  Color _statusBg(String s) => s == 'rejected'
      ? const Color(0xFFFEE2E2)
      : s == 'fulfilled'
          ? const Color(0xFFDCFCE7)
          : const Color(0xFFFFFBEB);
  Color _statusBorder(String s) => s == 'rejected'
      ? const Color(0xFFFCA5A5)
      : s == 'fulfilled'
          ? const Color(0xFFBBF7D0)
          : const Color(0xFFFDE68A);
  Color _statusFg(String s) => s == 'rejected'
      ? const Color(0xFFDC2626)
      : s == 'fulfilled'
          ? const Color(0xFF16A34A)
          : const Color(0xFFD97706);
}