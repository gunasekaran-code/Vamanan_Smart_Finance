import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../../models/genealogy_explorer_model.dart';
import '../../../services/genealogy_explorer_service.dart';
import '../../../shared/widgets/referral_tree_view.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// Shows the full downline tree (up to the backend's 5-level cap) rooted at
/// [rootNodeId], fetched in one call via GenealogyService.fetchDownline.
class NetworkNodesScreen extends StatefulWidget {
  final String rootNodeName;
  final String rootNodeId;

  const NetworkNodesScreen({
    super.key,
    required this.rootNodeName,
    required this.rootNodeId,
  });

  @override
  State<NetworkNodesScreen> createState() => _NetworkNodesScreenState();
}

class _NetworkNodesScreenState extends State<NetworkNodesScreen> {
  final GenealogyService _service = GenealogyService();

  List<GenealogyNode> _downline = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDownline();
  }

  Future<void> _loadDownline() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final nodes = await _service.fetchDownline(widget.rootNodeId);
      if (!mounted) return;
      setState(() {
        _downline = nodes;
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

  int get _totalNetworkSize =>
      _downline.fold(0, (sum, n) => sum + 1 + n.totalDownlineCount);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 720 ? 720.0 : screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E3A8A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.rootNodeName,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1E3A8A))),
            const Text('NETWORK TREE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Color(0xFF94A3B8))),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDownline,
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
                      _buildSummaryBar(),
                      const SizedBox(height: 20),
                      _buildBody(),
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

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.kBorder)),
      child: Row(
        children: [
          Expanded(child: _statTile('DIRECT REFERRALS', '${_downline.length}')),
          Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
          Expanded(child: _statTile('TOTAL NETWORK', '$_totalNetworkSize')),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1E3A8A))),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            OutlinedButton(
                onPressed: _loadDownline, child: const Text('RETRY')),
          ],
        ),
      );
    }
    if (_downline.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text('No downline members yet.',
              style: TextStyle(
                  color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        ),
      );
    }
    // Keyed by the loaded list so a pull-to-refresh resets expansion state.
    return ReferralTreeView(key: ObjectKey(_downline), nodes: _downline);
  }
}
