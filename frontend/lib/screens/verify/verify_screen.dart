import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';

class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  // TODO: wire up to GET /verifications/pending and
  // POST /verifications/:id/approve once the backend exists.
  static const _pending = [
    ('VEERASAMY.K', 'Loan LN-2026-0005 · EMI #4', '₹1,250'),
    ('Roki', 'Loan LN-2026-0001 · EMI #2', '₹2,063'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Verify',
      subtitle: 'Payment proofs awaiting approval. Visible to Super Admin, Admin and Staff.',
      children: [
        for (final p in _pending)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.kWarning,
                  child: Icon(Icons.receipt_long_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(p.$2, style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
                    ],
                  ),
                ),
                Text(p.$3, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}
