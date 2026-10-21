import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/services/attention_center_service.dart';

const _navy = AppColors.kPrimary;
const _gold = Color(0xFFB8962E);
const _cream = Color(0xFFFFFDF8);
const _muted = Color(0xFF94A3B8);
const _slate = Color(0xFF64748B);
const _newBg = Color(0xFFFDECEC);
const _newText = Color(0xFFD64545);
const _countBg = Color(0xFFF6EBCB);
const _countText = Color(0xFF7A5F12);

/// Opens the "needs attention" panel under the header bell.
/// Phones get a near full-width sheet; tablets/desktop a 420px dropdown
/// anchored to the right edge.
Future<void> showAttentionPanel(BuildContext context) {
  final router = GoRouter.of(context);
  AttentionCenter.instance.refresh();

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close notifications',
    barrierColor: Colors.black.withOpacity(0.25),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, _, __) => _AttentionPanelFrame(
      onOpen: (route) {
        Navigator.of(dialogContext).pop();
        router.go(route);
      },
    ),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.03), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _AttentionPanelFrame extends StatelessWidget {
  final ValueChanged<String> onOpen;

  const _AttentionPanelFrame({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isPhone = size.width < 600;
    final width = isPhone ? size.width - 24 : 420.0;

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(top: 60, right: isPhone ? 12 : 16, left: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width,
              maxHeight: size.height * (isPhone ? 0.8 : 0.75),
            ),
            child: Material(
              color: _cream,
              elevation: 18,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: AnimatedBuilder(
                animation: AttentionCenter.instance,
                builder: (context, _) => _AttentionPanel(
                  center: AttentionCenter.instance,
                  isPhone: isPhone,
                  onOpen: onOpen,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  final AttentionCenter center;
  final bool isPhone;
  final ValueChanged<String> onOpen;

  const _AttentionPanel({required this.center, required this.isPhone, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final categories = center.categories;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        Flexible(child: _buildBody(categories)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final total = center.totalCount;
    final fresh = center.totalNew;
    final narrow = MediaQuery.sizeOf(context).width < 380;

    return Container(
      color: _navy,
      padding: EdgeInsets.fromLTRB(isPhone ? 18 : 22, 16, 8, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      fresh > 0 ? 'LIVE · $fresh NEW' : 'LIVE',
                      style: const TextStyle(color: Color(0xFFE2BE55), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5),
                    ),
                    if (center.isLoading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.6, color: Color(0xFFE2BE55)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'All caught up'
                      : '$total ${total == 1 ? 'item needs' : 'items need'} attention',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: isPhone ? 17 : 19, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (fresh > 0)
            Material(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: center.markAllRead,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        narrow ? 'ALL READ' : 'MARK ALL AS READ',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<AttentionCategory> categories) {
    if (!center.hasLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: _navy))),
      );
    }

    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: _countBg, shape: BoxShape.circle),
              child: Icon(center.error != null ? Icons.wifi_off_rounded : Icons.check_rounded, color: _countText, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              center.error ?? 'Nothing needs your attention right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slate, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1EFF6)),
      itemBuilder: (_, i) => _CategoryTile(
        category: categories[i],
        isPhone: isPhone,
        onOpen: () => onOpen(categories[i].route),
        onMarkRead: () => center.markRead(categories[i].kind),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final AttentionCategory category;
  final bool isPhone;
  final VoidCallback onOpen;
  final VoidCallback onMarkRead;

  const _CategoryTile({
    required this.category,
    required this.isPhone,
    required this.onOpen,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final hasNew = category.newCount > 0;
    final previews = category.items.take(2).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(isPhone ? 16 : 20, 16, isPhone ? 14 : 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasNew ? _newText : Colors.transparent,
                  border: hasNew ? null : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _navy, fontSize: isPhone ? 15 : 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              if (hasNew) ...[
                _pill('${category.newCount} new', _newBg, _newText),
                const SizedBox(width: 8),
              ],
              _pill('${category.total}', _countBg, _countText, round: true),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in previews)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: item.headline,
                    style: TextStyle(color: _navy, fontSize: isPhone ? 13 : 14, fontWeight: FontWeight.w700),
                  ),
                  if (item.at != null)
                    TextSpan(
                      text: ' · ${_timeAgo(item.at!)}',
                      style: TextStyle(color: _muted, fontSize: isPhone ? 12 : 13, fontWeight: FontWeight.w500),
                    ),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (category.total > previews.length)
            Text(
              '+${category.total - previews.length} more',
              style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              _action('OPEN', Icons.arrow_forward_rounded, _gold, onOpen, trailingIcon: true),
              const SizedBox(width: 12),
              _action(
                hasNew ? 'MARK READ' : 'READ',
                Icons.check_rounded,
                hasNew ? _slate : const Color(0xFFCBD5E1),
                hasNew ? onMarkRead : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg, {bool round = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: EdgeInsets.symmetric(horizontal: round ? 10 : 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }

  Widget _action(String label, IconData icon, Color color, VoidCallback? onTap, {bool trailingIcon = false}) {
    final text = Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.6));
    final glyph = Icon(icon, color: color, size: 16);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: trailingIcon
              ? [text, const SizedBox(width: 6), glyph]
              : [glyph, const SizedBox(width: 6), text],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.isNegative || diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 365) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 365}y ago';
  }
}
