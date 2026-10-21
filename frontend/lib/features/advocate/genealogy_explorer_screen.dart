import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../../models/genealogy_explorer_model.dart';
import '../../../services/genealogy_explorer_service.dart';
import 'fraud_detection_widget.dart';
import 'network_nodes_screen.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class GenealogyExplorerScreen extends StatefulWidget {
  const GenealogyExplorerScreen({super.key});

  @override
  State<GenealogyExplorerScreen> createState() =>
      _GenealogyExplorerScreenState();
}

class _GenealogyExplorerScreenState extends State<GenealogyExplorerScreen> {
  final GenealogyService _service = GenealogyService();
  final TextEditingController _nodeSearchController = TextEditingController();

  /// Lets the yield run re-trigger the integrity scan, since crediting a
  /// cashback cycle can change the payout-vs-cycle-value findings.
  final GlobalKey<FraudDetectionWidgetState> _fraudKey =
      GlobalKey<FraudDetectionWidgetState>();
  Timer? _debounce;

  List<GenealogyNode> _allNodes = [];
  List<GenealogyNode> _visibleNodes = [];
  bool _isLoading = true;
  bool _isProcessingYield = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRootUsers();
    _nodeSearchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nodeSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadRootUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final nodes = await _service.fetchRootUsers();
      if (!mounted) return;
      setState(() {
        _allNodes = nodes;
        _visibleNodes = _applyFilter(nodes, _nodeSearchController.text);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _visibleNodes = _applyFilter(_allNodes, _nodeSearchController.text);
      });
    });
  }

  List<GenealogyNode> _applyFilter(List<GenealogyNode> nodes, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return nodes;
    return nodes.where((n) {
      return n.name.toLowerCase().contains(q) ||
          n.systemId.toLowerCase().contains(q) ||
          (n.email ?? '').toLowerCase().contains(q);
    }).toList();
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

    if (confirmed != true) return;

    setState(() => _isProcessingYield = true);
    try {
      final message = await _service.processMonthlyYield();
      if (!mounted) return;
      ToastService.show(
          title: 'Success', message: message, type: ToastType.success);
      _loadRootUsers();
      _fraudKey.currentState?.runScan();
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
          title: 'Failed', message: e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isProcessingYield = false);
    }
  }

  void _navigateToNetworkNodes(GenealogyNode node) =>
      _openNetworkNodes(node.id, node.name);

  /// Opens the tree for a raw `users.id`. The fraud panel reports flagged
  /// accounts by id, so it routes through here rather than through a
  /// GenealogyNode it never loaded.
  void _openNetworkNodes(String userId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetworkNodesScreen(
          rootNodeName: name,
          rootNodeId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 720 ? 720.0 : screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRootUsers,
          color: const Color(0xFF1E3A8A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Global Search (decorative placeholder — wire up to
                      // your app-wide search when that endpoint exists).
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.kBorder),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Search users, orders, assets...',
                            hintStyle: TextStyle(
                                color: AppColors.kTextMuted, fontSize: 14),
                            prefixIcon:
                                Icon(Icons.search, color: AppColors.kTextMuted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Process Yield Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isProcessingYield ? null : _handleProcessYield,
                          icon: _isProcessingYield
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.bolt, size: 16),
                          label: Text(
                            _isProcessingYield
                                ? 'PROCESSING...'
                                : 'PROCESS MONTHLY YIELD',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Main Explorer Content
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.kBorder),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GENEALOGY EXPLORER',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 4),
                            Text(
                              'AUDIT REFERRAL RELATIONSHIPS — FLAT 2% DIRECT COMMISSION',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color:
                                      const Color(0xFF94A3B8).withOpacity(0.8),
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 24),

                            // Node Search
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.kBorder),
                              ),
                              child: TextField(
                                controller: _nodeSearchController,
                                decoration: InputDecoration(
                                  hintText: 'SEARCH INVESTOR NODE...',
                                  hintStyle: const TextStyle(
                                      color: AppColors.kTextMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic),
                                  prefixIcon: const Icon(Icons.search,
                                      color: AppColors.kTextMuted, size: 20),
                                  suffixIcon: _nodeSearchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.clear,
                                              size: 18,
                                              color: AppColors.kTextMuted),
                                          onPressed: () {
                                            _nodeSearchController.clear();
                                          },
                                        ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            _buildNodeListArea(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Scans the whole referral network and lets the
                      // auditor jump from any flagged account straight into
                      // that account's tree.
                      FraudDetectionWidget(
                        key: _fraudKey,
                        onInspectSubject: _openNetworkNodes,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeListArea() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: AppLoader()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadRootUsers,
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    if (_visibleNodes.isEmpty) {
      final hasQuery = _nodeSearchController.text.trim().isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            hasQuery
                ? 'No investors match your search.'
                : 'No investors found.',
            style: const TextStyle(
                color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _visibleNodes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildNodeCard(_visibleNodes[index]),
    );
  }

  Widget _buildNodeCard(GenealogyNode node) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(
                  node.name.isNotEmpty
                      ? node.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E3A8A),
                            fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(node.systemId,
                            style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        if (node.kycStatus != null) ...[
                          const SizedBox(width: 8),
                          _kycBadge(node.kycStatus),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          InkWell(
            onTap: () => _navigateToNetworkNodes(node),
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('INSPECT TREE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1)),
                  Icon(Icons.account_tree_outlined,
                      size: 16,
                      color: const Color(0xFF94A3B8).withOpacity(0.5)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _kycBadge(String? status) {
    final s = (status ?? '').toLowerCase();
    final isVerified = s == 'verified' || s == 'approved';
    final color =
        isVerified ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(
        (status ?? 'PENDING').toUpperCase(),
        style:
            TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}
