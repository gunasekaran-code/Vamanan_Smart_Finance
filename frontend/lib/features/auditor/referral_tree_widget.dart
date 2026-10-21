import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../models/genealogy_explorer_model.dart';
import '../../services/genealogy_explorer_service.dart';
import '../../shared/widgets/referral_tree_view.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// "YOUR REFERRAL TREE" — the logged-in user's downline (up to the backend's
/// 5-level cap) from `get_genealogy.php`, shown as a collapsible tree.
/// Nodes with a downline expand/collapse on tap; leaves show a person icon.
class ReferralTreeWidget extends StatefulWidget {
  final String userId;
  final String commissionRate;

  const ReferralTreeWidget({
    super.key,
    required this.userId,
    this.commissionRate = '2%',
  });

  @override
  State<ReferralTreeWidget> createState() => _ReferralTreeWidgetState();
}

class _ReferralTreeWidgetState extends State<ReferralTreeWidget> {
  final GenealogyService _service = GenealogyService();

  final Color _navyBlue = AppColors.kPrimary;
  final Color _mutedText = const Color(0xFF94A3B8);

  List<GenealogyNode> _tree = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReferralTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final nodes = _sorted(await _service.fetchDownline(widget.userId));
      if (!mounted) return;
      setState(() {
        _tree = nodes;
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

  /// The API returns rows unordered; keep a stable join order (by user id)
  /// at every level of the tree.
  List<GenealogyNode> _sorted(List<GenealogyNode> nodes) {
    final list = nodes.map((n) => n.copyWith(downline: _sorted(n.downline))).toList();
    list.sort((a, b) {
      final ai = int.tryParse(a.id), bi = int.tryParse(b.id);
      if (ai != null && bi != null) return ai.compareTo(bi);
      return a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: _navyBlue,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'YOUR REFERRAL TREE',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0),
          ),
          const SizedBox(height: 10),
          Text(
            'SEE YOUR DIRECT MEMBERS — FLAT ${widget.commissionRate} REFERRAL',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedText, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 3.0),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: List.generate(5, (i) => _legendChip(i + 1)),
          ),
        ],
      ),
    );
  }

  Widget _legendChip(int level) {
    final style = ReferralTreeView.styleFor(level);
    return Container(
      width: 66,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text('L$level', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildBody() {
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
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: _mutedText, fontSize: 13)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('RETRY')),
          ],
        ),
      );
    }

    if (_tree.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Icon(Icons.person_search_outlined, size: 48, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'NO MEMBERS FOUND. EXPAND YOUR NETWORK.',
              style: TextStyle(color: _mutedText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
            ),
          ],
        ),
      );
    }

    // Keyed by the loaded list so a reload resets expansion state.
    return ReferralTreeView(key: ObjectKey(_tree), nodes: _tree);
  }
}
