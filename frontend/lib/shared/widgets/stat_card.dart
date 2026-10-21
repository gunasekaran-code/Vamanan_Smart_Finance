import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:frontend/core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? badgeText;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? badgeBackgroundColor;
  final Color? badgeTextColor;
  final Color? valueColor;
  final Color? labelColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.badgeText,
    this.backgroundColor,
    this.borderColor,
    this.badgeBackgroundColor,
    this.badgeTextColor,
    this.valueColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? AppColors.kSurface;
    final effectiveBorderColor = borderColor ?? color.withOpacity(0.35);
    final effectiveIconBgColor = color.withOpacity(0.12);
    final effectiveBadgeBgColor =
        badgeBackgroundColor ?? color.withOpacity(0.15);
    final effectiveBadgeTextColor = badgeTextColor ?? color;
    final effectiveValueColor = valueColor ?? AppColors.kPrimary;
    final effectiveLabelColor = labelColor ?? AppColors.kTextMuted;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compact sizing for narrow cards (small phones / 4-up rows).
        final isCompact = constraints.maxWidth < 180;
        final padding = isCompact ? 14.0 : 18.0;
        final iconBox = isCompact ? 36.0 : 42.0;

        final contentGap = constraints.hasBoundedHeight
            ? const Spacer()
            : const SizedBox(height: 24);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: effectiveBgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: effectiveBorderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Soft decorative accent in the corner.
              Positioned(
                right: -28,
                bottom: -28,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Icon Container on Left, Badge Pill on Right
                    Row(
                      children: [
                        Container(
                          width: iconBox,
                          height: iconBox,
                          decoration: BoxDecoration(
                            color: effectiveIconBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: iconBox * 0.48),
                        ),
                        const SizedBox(width: 8),
                        const Spacer(),
                        if (badgeText != null && badgeText!.isNotEmpty)
                          Flexible(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: effectiveBadgeBgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                badgeText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isCompact ? 9 : 10,
                                  fontWeight: FontWeight.w800,
                                  color: effectiveBadgeTextColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    contentGap,
                    // Label Text
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 9 : 10,
                        fontWeight: FontWeight.w800,
                        color: effectiveLabelColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Value Text
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: isCompact ? 20 : 24,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: effectiveValueColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Responsive grid for [StatCard]s. Every card gets the same fixed height
/// (instead of a width-driven aspect ratio, which stretches cards on
/// tablets), with 2 columns on phones/tablets and up to 4 on wide screens.
class StatCardGrid extends StatelessWidget {
  final List<Widget> children;

  const StatCardGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmallMobile = width < 360;

        final int columns;
        if (width >= 840) {
          columns = math.min(4, children.length);
        } else if (width >= 600 && children.length % 3 == 0) {
          columns = 3;
        } else {
          columns = 2;
        }

        final spacing = isSmallMobile ? 10.0 : 14.0;
        final cardHeight = isSmallMobile ? 138.0 : (width < 600 ? 148.0 : 158.0);

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: math.max(1, columns),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: cardHeight,
          ),
          children: children,
        );
      },
    );
  }
}
