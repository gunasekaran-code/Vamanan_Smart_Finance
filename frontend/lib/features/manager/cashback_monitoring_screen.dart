import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class CashbackMonitoringScreen extends StatelessWidget {
  const CashbackMonitoringScreen({super.key});

  // Mock data matching the provided image
  final List<Map<String, String>> _recipients = const [
    {
      'initial': 'N',
      'name': 'NANDHA KUMAR.M',
      'amount': '₹73,398.6',
    },
    {
      'initial': 'A',
      'name': 'ARUN.K',
      'amount': '₹73,398.6',
    },
    {
      'initial': 'K',
      'name': 'KANAGARAJ K',
      'amount': '₹58,718.88',
    },
    {
      'initial': 'A',
      'name': 'AKILA.M',
      'amount': '₹27,961.92',
    },
    {
      'initial': 'T',
      'name': 'TIRUPARANKUNDRAM MURUGAN',
      'amount': '₹23,394',
    },
  ];

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
                  _buildTotalPayoutCard(),
                  const SizedBox(height: 20),
                  _buildActiveRecipientsCard(),
                  const SizedBox(height: 32),
                  ..._recipients.map((data) => _buildRecipientCard(data)),
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
                  '₹0',
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
                  '100 Accounts',
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

  Widget _buildRecipientCard(Map<String, String> data) {
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
                data['initial']!,
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
                  data['name']!,
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
                const Text(
                  'STANDARD WALLET',
                  style: TextStyle(
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
                data['amount']!,
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
}