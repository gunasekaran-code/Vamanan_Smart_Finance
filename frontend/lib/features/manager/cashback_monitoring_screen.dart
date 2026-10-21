import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../models/cashback_monitoring_model.dart';
import '../../services/cashback_monitoring_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class CashbackMonitoringScreen extends StatefulWidget {
  const CashbackMonitoringScreen({super.key});

  @override
  State<CashbackMonitoringScreen> createState() =>
      _CashbackMonitoringScreenState();
}

class _CashbackMonitoringScreenState extends State<CashbackMonitoringScreen> {
  final CashbackMonitoringService _service = CashbackMonitoringService();
  CashbackMonitoringResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchMonitoringData();
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  const SizedBox(height: 32),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: AppLoader()),
                    )
                  else if (_error != null)
                    _buildErrorState()
                  else ...[
                    _buildTotalPayoutCard(),
                  const SizedBox(height: 20),
                  _buildActiveRecipientsCard(),
                  const SizedBox(height: 32),
                  if (_result!.entries.isEmpty)
                    _buildEmptyState()
                  else
                    ..._result!.entries.map(_buildRecipientCard),
                  ],
                  const SizedBox(height: 40), // Bottom scroll padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Icon(
            Icons.receipt_long_outlined,
            color: AppColors.goldColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'OPERATIONAL LEDGER: CASHBACK\nMONITORING',
            style: const TextStyle(
              color: AppColors.kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ),
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh cashback data',
          icon: const Icon(Icons.refresh_rounded, color: AppColors.kPrimary),
        ),
      ],
    );
  }

  Widget _buildTotalPayoutCard() {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.kPrimary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background faded watermark icon
          Positioned(
            right: 10,
            top: -20,
            child: Icon(
              Icons.monetization_on,
              size: 150,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'TOTAL PAYOUT VOLUME',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatAmount(_result?.totalAmount ?? 0),
                  style: const TextStyle(
                    color: AppColors.goldColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRecipientsCard() {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background faded watermark icon
          Positioned(
            right: 10,
            top: 5,
            child: Icon(
              Icons.people_alt,
              size: 120,
              color: AppColors.kPrimary.withOpacity(0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ACTIVE RECIPIENTS',
                  style: TextStyle(
                    color: AppColors.kTextMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_result?.count ?? 0} Accounts',
                  style: const TextStyle(
                    color: AppColors.kPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientCard(CashbackMonitoringEntry data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Squircle Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.kPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                data.initial,
                style: const TextStyle(
                  color: AppColors.goldColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    color: AppColors.kPrimary,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data.walletType ?? 'STANDARD WALLET',
                  style: const TextStyle(
                    color: AppColors.kTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Amount and Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatAmount(data.amount),
                style: const TextStyle(
                  color: AppColors.kPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'CURRENT LIQUIDITY',
                style: TextStyle(
                  color: AppColors.goldColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.kDanger, size: 42),
        const SizedBox(height: 12),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.kTextMuted),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('TRY AGAIN'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'No cashback records found.',
          style: TextStyle(color: AppColors.kTextMuted),
        ),
      ),
    );
  }

  String _formatAmount(double amount) =>
      '₹${amount.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '')}';
}