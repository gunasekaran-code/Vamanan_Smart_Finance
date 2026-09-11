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
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? AppColors.kSurface;
    final effectiveBorderColor = borderColor ?? color.withOpacity(0.35);
    final effectiveIconBgColor = color.withOpacity(0.12);
    final effectiveBadgeBgColor = badgeBackgroundColor ?? color.withOpacity(0.15);
    final effectiveBadgeTextColor = badgeTextColor ?? color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentGap = constraints.hasBoundedHeight
              ? const Spacer()
              : const SizedBox(height: 24);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Icon Container on Left, Badge Pill on Right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: effectiveIconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  if (badgeText != null && badgeText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: effectiveBadgeBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: effectiveBadgeTextColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                ],
              ),
              contentGap,
              // Label Text
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kTextMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Value Text
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}