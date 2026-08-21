import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Consistent content wrapper for every tab page — keeps spacing and
/// typography identical while each screen only supplies its own title
/// and body widgets. Scrollable by default so pages never need to
/// worry about overflow.
class AppPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final List<Widget> children;

  const AppPage({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    required this.children,
  }) : assert(subtitle == null || subtitleWidget == null);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.kBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.kTextDark,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
            ),
          ] else if (subtitleWidget != null) ...[
            const SizedBox(height: 4),
            subtitleWidget!,
          ],
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
