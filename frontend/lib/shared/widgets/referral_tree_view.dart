import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../models/genealogy_explorer_model.dart';

/// Renders a genealogy downline as a collapsible tree: one card per member,
/// colour-coded by level (L1 gold, L2 blue, L3 gold, L4 slate, L5 blue), with
/// a vertical guide line linking each parent to its downline. Members with a
/// downline expand/collapse on tap; leaves show a person icon.
class ReferralTreeView extends StatefulWidget {
  final List<GenealogyNode> nodes;

  const ReferralTreeView({super.key, required this.nodes});

  /// Accent / tint / text colours for a level, shared with legend chips.
  static ReferralLevelStyle styleFor(int level) {
    if (level == 4) {
      return const ReferralLevelStyle(
          accent: Color(0xFF475569), tint: Color(0xFFF8FAFC), text: Color(0xFF334155));
    }
    if (level.isOdd) {
      return const ReferralLevelStyle(
          accent: Color(0xFFCFAE4A), tint: Color(0xFFFAF7EE), text: Color(0xFF9A7A1E));
    }
    return const ReferralLevelStyle(
        accent: Color(0xFF4F7FE8), tint: Color(0xFFEFF4FD), text: Color(0xFF2F5BC4));
  }

  @override
  State<ReferralTreeView> createState() => _ReferralTreeViewState();
}

class _ReferralTreeViewState extends State<ReferralTreeView> {
  final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  final Color _navyBlue = AppColors.kPrimary;
  final Color _mutedText = const Color(0xFF94A3B8);

  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _expandFirstLevel();
  }

  @override
  void didUpdateWidget(covariant ReferralTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.nodes, widget.nodes) && _expanded.isEmpty) {
      _expandFirstLevel();
    }
  }

  // Open the first level by default so direct members' downlines show.
  void _expandFirstLevel() {
    _expanded.addAll(widget.nodes.where((n) => n.downline.isNotEmpty).map((n) => n.id));
  }

  void _toggle(GenealogyNode node) {
    if (node.downline.isEmpty) return;
    setState(() {
      if (!_expanded.remove(node.id)) _expanded.add(node.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _buildNodes(widget.nodes, 1),
    );
  }

  List<Widget> _buildNodes(List<GenealogyNode> nodes, int depth) {
    return [
      for (var i = 0; i < nodes.length; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        _buildBranch(nodes[i], depth),
      ],
    ];
  }

  Widget _buildBranch(GenealogyNode node, int depth) {
    final isOpen = _expanded.contains(node.id) && node.downline.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNodeCard(node, depth, isOpen),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: isOpen
              ? Padding(
                  // Vertical guide line linking the parent to its downline.
                  padding: const EdgeInsets.only(left: 16),
                  child: Container(
                    padding: const EdgeInsets.only(left: 26, top: 12),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildNodes(node.downline, depth + 1),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildNodeCard(GenealogyNode node, int depth, bool isOpen) {
    final level = node.level > 0 ? node.level : depth;
    final style = ReferralTreeView.styleFor(level);
    final hasChildren = node.downline.isNotEmpty;
    final radius = BorderRadius.circular(20);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          color: style.accent,
          padding: const EdgeInsets.only(left: 5),
          child: Material(
            color: style.tint,
            child: InkWell(
              onTap: hasChildren ? () => _toggle(node) : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: Row(
                  children: [
                    _leadingBox(style, hasChildren, isOpen),
                    const SizedBox(width: 18),
                    Expanded(child: _nodeDetails(node, level, style)),
                    if (node.isKycVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_user_outlined, color: AppColors.goldColor, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leadingBox(ReferralLevelStyle style, bool hasChildren, bool isOpen) {
    final IconData icon = !hasChildren
        ? Icons.person_outline
        : (isOpen ? Icons.keyboard_arrow_down : Icons.chevron_right);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Icon(icon, color: style.text, size: 22),
    );
  }

  Widget _nodeDetails(GenealogyNode node, int level, ReferralLevelStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                node.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _navyBlue, fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text('L$level', style: TextStyle(color: style.text, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 18,
          runSpacing: 4,
          children: [
            Text(
              node.systemId.toUpperCase(),
              style: TextStyle(color: _mutedText, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5),
            ),
            if (node.totalInvestment > 0)
              Text(
                _money.format(node.totalInvestment),
                style: const TextStyle(color: Color(0xFFB08A1E), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
              ),
          ],
        ),
      ],
    );
  }
}

class ReferralLevelStyle {
  final Color accent;
  final Color tint;
  final Color text;

  const ReferralLevelStyle({required this.accent, required this.tint, required this.text});
}
