import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_loader.dart';
import '../../models/advocate_archive_model.dart';
import '../../services/advocate_archive_service.dart';

const Color _kNavy = Color(0xFF1E293B);
const Color _kMuted = Color(0xFF94A3B8);
const Color _kSoft = Color(0xFFF8FAFC);
const Color _kSoftBorder = Color(0xFFF1F5F9);
const Color _kGoldTint = Color(0xFFFBF8EE);

/// Full agreement deed for one archived agreement, opened from the eye icon
/// on [ArchiveAgreementsScreen].
///
/// Lives at `/archive/agreement?id=N` inside the app shell, so the header
/// shows a back arrow and the bottom nav stays visible. The row tapped in the
/// archive is passed as [initial] for an instant first paint; the page then
/// re-reads the agreement from `advocate/stats.php`, which is also how it
/// loads on its own after a browser refresh.
class AgreementVerificationScreen extends StatefulWidget {
  final int agreementId;
  final AgreementArchiveItem? initial;

  const AgreementVerificationScreen({
    super.key,
    required this.agreementId,
    this.initial,
  });

  @override
  State<AgreementVerificationScreen> createState() =>
      _AgreementVerificationScreenState();
}

class _AgreementVerificationScreenState
    extends State<AgreementVerificationScreen> {
  AgreementArchiveItem? _item;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _item = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh =
          await AdvocateArchiveService.fetchAgreementById(widget.agreementId);
      if (!mounted) return;
      setState(() {
        _item = fresh;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;

    Widget body;
    if (item == null && _loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 120),
        child: Center(child: AppLoader()),
      );
    } else if (item == null) {
      body = _ErrorState(
          message: _error ?? 'Agreement not found.', onRetry: _load);
    } else {
      body = _AgreementDocument(item: item, refreshing: _loading);
    }

    return ColoredBox(
      color: AppColors.kBackground,
      child: RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 12,
                vertical: isTablet ? 32 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // A failed background refresh keeps the data already
                      // shown and just flags it.
                      if (item != null && _error != null) ...[
                        _RefreshFailedBanner(message: _error!, onRetry: _load),
                        const SizedBox(height: 16),
                      ],
                      body,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// DOCUMENT
// ============================================================================
class _AgreementDocument extends StatelessWidget {
  final AgreementArchiveItem item;
  final bool refreshing;

  const _AgreementDocument({required this.item, required this.refreshing});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final pad = isTablet ? 48.0 : 20.0;
    final gap = isTablet ? 40.0 : 28.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
        border: Border.all(color: _kSoftBorder),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(refreshing: refreshing, compact: !isTablet),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, gap, pad, pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TitleBlock(item: item, isTablet: isTablet),
                SizedBox(height: isTablet ? 32 : 24),
                const Divider(color: _kNavy, thickness: 1.5, height: 1.5),
                SizedBox(height: gap),
                _EstablishedLine(item: item, isTablet: isTablet),
                SizedBox(height: gap),
                _PartiesSection(item: item, isTablet: isTablet),
                SizedBox(height: gap),
                _ProductSpecifications(item: item, isTablet: isTablet),
                SizedBox(height: gap),
                const Divider(color: _kSoftBorder, thickness: 1.5, height: 1.5),
                SizedBox(height: gap),
                _SignatureSection(item: item, isTablet: isTablet),
                SizedBox(height: gap),
                const Divider(color: _kSoftBorder, thickness: 1.5, height: 1.5),
                SizedBox(height: isTablet ? 32 : 24),
                _StatusBanner(item: item, isTablet: isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool refreshing;
  final bool compact;

  const _TopBar({required this.refreshing, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 24, vertical: compact ? 12 : 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kSoftBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kNavy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_document,
                color: AppColors.goldColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'AGREEMENT VERIFICATION',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _kMuted,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: compact ? 2 : 4,
              ),
            ),
          ),
          if (refreshing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final AgreementArchiveItem item;
  final bool isTablet;

  const _TitleBlock({required this.item, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final logoSize = isTablet ? 64.0 : 56.0;
    return Column(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _kNavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.verified, color: AppColors.goldColor),
          ),
        ),
        SizedBox(height: isTablet ? 24 : 18),
        Text(
          item.agreementType,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _kNavy,
            fontSize: isTablet ? 34 : 22,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'AGREEMENT REFERENCE ID: ${item.referenceId}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.goldColor,
            fontSize: isTablet ? 15 : 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: isTablet ? 5 : 2,
          ),
        ),
      ],
    );
  }
}

class _EstablishedLine extends StatelessWidget {
  final AgreementArchiveItem item;
  final bool isTablet;

  const _EstablishedLine({required this.item, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.goldColor, width: 3)),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            color: _kNavy,
            fontSize: isTablet ? 17 : 13,
            fontWeight: FontWeight.w900,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'ESTABLISHED ON '),
            TextSpan(
              text: item.date.isEmpty ? '—' : item.date,
              style: const TextStyle(
                color: AppColors.goldColor,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.goldColor,
              ),
            ),
            TextSpan(text: ' AT THE ${item.branch}.'),
          ],
        ),
      ),
    );
  }
}

class _PartiesSection extends StatelessWidget {
  final AgreementArchiveItem item;
  final bool isTablet;

  const _PartiesSection({required this.item, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final company = _PartyCard(
      label: 'COMPANY (ISSUER)',
      title: item.companyName,
      subtitle: item.companyAddress,
      isTablet: isTablet,
    );
    final customer = _PartyCard(
      label: 'CUSTOMER DETAILS',
      title: item.customerName.toUpperCase(),
      subtitle: item.maskedIdentity,
      extra: item.customerEmail.isEmpty ? null : item.customerEmail,
      isTablet: isTablet,
    );

    if (!isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [company, const SizedBox(height: 16), customer],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: company),
          const SizedBox(width: 32),
          Expanded(child: customer),
        ],
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;
  final String? extra;
  final bool isTablet;

  const _PartyCard({
    required this.label,
    required this.title,
    required this.subtitle,
    this.extra,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 36 : 20),
      decoration: BoxDecoration(
        color: _kSoft,
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        border: Border.all(color: _kSoftBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallLabel(label),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: _kNavy,
              fontSize: isTablet ? 17 : 15,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: isTablet ? 15 : 12,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
              height: 1.5,
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 4),
            Text(
              extra!,
              style: const TextStyle(
                color: _kMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductSpecifications extends StatelessWidget {
  final AgreementArchiveItem item;
  final bool isTablet;

  const _ProductSpecifications({required this.item, required this.isTablet});

  static String _price(double? value) {
    if (value == null) return '—';
    final hasPaise = value != value.roundToDouble();
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: hasPaise ? 2 : 0,
    ).format(value);
  }

  static String _weight(double? value) {
    if (value == null) return '—';
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(3);
    return '$text Grams';
  }

  @override
  Widget build(BuildContext context) {
    final specs = [
      _Spec('PRODUCT NAME', (item.productName ?? '—').toUpperCase(), _kNavy),
      _Spec('TOTAL PRICE', _price(item.price), AppColors.goldColor),
      _Spec('GOLD WEIGHT', _weight(item.weight), _kNavy),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kNavy,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _kNavy.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.description_outlined,
                  color: AppColors.goldColor, size: 20),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                'PRODUCT SPECIFICATIONS',
                style: TextStyle(
                  color: _kNavy,
                  fontSize: isTablet ? 19 : 15,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 32 : 20),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 36 : 20,
            vertical: isTablet ? 32 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFD),
            borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
            border: Border.all(color: _kSoftBorder),
          ),
          child: isTablet
              ? IntrinsicHeight(
                  child: Row(
                    children: [
                      for (var i = 0; i < specs.length; i++) ...[
                        if (i > 0) ...[
                          const VerticalDivider(
                              color: Color(0xFFE2E8F0), width: 1, thickness: 1),
                          const SizedBox(width: 36),
                        ],
                        Expanded(child: _SpecCell(spec: specs[i], large: true)),
                      ],
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < specs.length; i++) ...[
                      if (i > 0)
                        const Divider(color: Color(0xFFE2E8F0), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: _SpecCell(spec: specs[i], large: false),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _Spec {
  final String label;
  final String value;
  final Color color;
  const _Spec(this.label, this.value, this.color);
}

class _SpecCell extends StatelessWidget {
  final _Spec spec;
  final bool large;

  const _SpecCell({required this.spec, required this.large});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallLabel(spec.label),
        const SizedBox(height: 10),
        Text(
          spec.value,
          style: TextStyle(
            color: spec.color,
            fontSize: large ? 17 : 15,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _SignatureSection extends StatelessWidget {
  final AgreementArchiveItem item;
  final bool isTablet;

  const _SignatureSection({required this.item, required this.isTablet});

  static final DateFormat _ts = DateFormat('d/M/y');

  @override
  Widget build(BuildContext context) {
    final blocks = [
      _SignatureBlock(
        caption: 'COMPANY AUTHORIZATION',
        name: 'VAMANAN ENTERPRISES V',
        icon: Icons.account_balance_outlined,
        stamp: null,
        active: false,
      ),
      _SignatureBlock(
        caption: 'AUTHORIZED ADVOCATE',
        name: 'ADVOCATE VERIFICATION SEAL',
        icon: Icons.verified_user_outlined,
        stamp: item.isAdvocateApproved
            ? 'APPROVED BY ADVOCATE'
            : 'AWAITING ADVOCATE',
        timestamp: item.advocateSignedAt == null
            ? null
            : 'TS: ${_ts.format(item.advocateSignedAt!.toLocal())}',
        active: item.isAdvocateApproved,
      ),
      _SignatureBlock(
        caption: 'CUSTOMER SIGNATURE',
        name: item.customerName.toUpperCase(),
        icon: Icons.check_circle_outline,
        stamp: item.isCustomerSigned ? 'CUSTOMER SIGNED' : 'AWAITING SIGNATURE',
        timestamp: item.customerSignedAt == null
            ? null
            : 'TS: ${_ts.format(item.customerSignedAt!.toLocal())}',
        active: item.isCustomerSigned,
      ),
    ];

    if (!isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            blocks[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(width: 40),
          Expanded(child: blocks[i]),
        ],
      ],
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  final String caption;
  final String name;
  final IconData icon;
  final String? stamp;
  final String? timestamp;
  final bool active;

  const _SignatureBlock({
    required this.caption,
    required this.name,
    required this.icon,
    required this.stamp,
    this.timestamp,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.goldColor : _kMuted.withOpacity(0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 104,
          decoration: BoxDecoration(
            color: active ? _kGoldTint : _kSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border(
              bottom: BorderSide(
                color: active
                    ? AppColors.goldColor.withOpacity(0.2)
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              if (stamp != null) ...[
                const SizedBox(height: 8),
                Text(
                  stamp!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                  ),
                ),
              ],
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  timestamp!,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(child: _SmallLabel(caption, spacing: 3)),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _kNavy,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final AgreementArchiveItem item;
  final bool isTablet;

  const _StatusBanner({required this.item, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final complete = item.isAdvocateApproved && item.isCustomerSigned;
    final label = complete
        ? 'AGREEMENT APPROVED & SIGNED'
        : item.isAdvocateApproved
            ? 'APPROVED · AWAITING CUSTOMER SIGNATURE'
            : 'PENDING ADVOCATE APPROVAL';

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 20, vertical: isTablet ? 24 : 18),
      decoration: BoxDecoration(
        color: _kGoldTint,
        borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
        border:
            Border.all(color: AppColors.goldColor.withOpacity(0.25), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            complete ? Icons.check_circle_outline : Icons.pending_outlined,
            color: AppColors.goldColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.goldColor,
                fontSize: isTablet ? 17 : 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SMALL PIECES
// ============================================================================
class _SmallLabel extends StatelessWidget {
  final String text;
  final double spacing;

  const _SmallLabel(this.text, {this.spacing = 2.5});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _kMuted,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        letterSpacing: spacing,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: _kMuted, size: 36),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('RETRY'),
          ),
        ],
      ),
    );
  }
}

class _RefreshFailedBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RefreshFailedBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.kDanger.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kDanger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.kDanger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not refresh: $message',
              style: const TextStyle(color: AppColors.kTextMuted, fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
