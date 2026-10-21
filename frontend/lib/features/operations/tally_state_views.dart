import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

/// Shared navy/gold palette for the Accounting Hub, so the seven views under
/// `TallyIntegrationScreen` don't each repeat the same literals.
const Color kTallyNavy = Color(0xFF1E3A8A);
const Color kTallyGold = Color(0xFFD97706);
const Color kTallyAmber = Color(0xFFFBBF24);
const Color kTallyMuted = Color(0xFF94A3B8);
const Color kTallySlate = Color(0xFF64748B);
const Color kTallyTint = Color(0xFFF8FAFC);

/// The rounded white card every panel in the hub sits in.
class TallyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const TallyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: child,
    );
  }
}

/// Spinner shown while a panel's first load is in flight.
class TallyLoadingCard extends StatelessWidget {
  final String label;

  const TallyLoadingCard({super.key, this.label = 'LOADING'});

  @override
  Widget build(BuildContext context) {
    return TallyCard(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: kTallyGold),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: kTallyMuted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Failure state with a retry, used wherever a fetch throws.
class TallyErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TallyErrorCard({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return TallyCard(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 32, color: kTallyMuted),
          const SizedBox(height: 16),
          Text(
            message.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.kDanger,
              letterSpacing: 1,
              height: 1.6,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text(
                'RETRY',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kTallyGold,
                side: const BorderSide(color: Color(0xFFFDE68A)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Nothing here yet" placeholder for an endpoint that returned no rows.
class TallyEmptyCard extends StatelessWidget {
  final String message;

  const TallyEmptyCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return TallyCard(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: kTallyMuted,
          letterSpacing: 1.5,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Scrollable, monospace dump of the generated Tally XML, shown by the
/// PREVIEW buttons on the ledger and voucher views.
class TallyXmlPreviewDialog extends StatelessWidget {
  final String title;
  final String xml;

  const TallyXmlPreviewDialog({super.key, required this.title, required this.xml});

  static Future<void> show(BuildContext context, String title, String xml) {
    return showDialog<void>(
      context: context,
      builder: (_) => TallyXmlPreviewDialog(title: title, xml: xml),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kTallyNavy,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20, color: kTallyMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.kBorder),
            Flexible(
              child: Container(
                color: kTallyTint,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: SelectableText(
                    xml,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.5,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
