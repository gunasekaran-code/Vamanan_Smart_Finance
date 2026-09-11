import 'package:flutter/material.dart';

import 'package:frontend/core/theme/app_theme.dart';

/// Large rounded card with a header row and a centered empty state —
/// the same look [SupportScreen] uses, shared so every "coming soon" /
/// zero-records page (Agreements, Archive, Disputes, Rules, ...) stays
/// visually consistent without copy-pasting the card each time.
class EmptyStateCard extends StatelessWidget {
  final IconData headerIcon;
  final String headerLabel;
  final IconData emptyIcon;
  final String emptyLabel;

  const EmptyStateCard({
    super.key,
    required this.headerIcon,
    required this.headerLabel,
    required this.emptyIcon,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 500,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: Colors.amber.shade600, size: 22),
              const SizedBox(width: 12),
              Text(
                headerLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 64, color: Colors.grey.shade100),
                  const SizedBox(height: 20),
                  Text(
                    emptyLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade400,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
