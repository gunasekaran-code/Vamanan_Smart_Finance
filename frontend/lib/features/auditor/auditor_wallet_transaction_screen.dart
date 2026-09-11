import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';

// --- Dummy Data Model ---
class WalletTransaction {
  final String id;
  final String details;
  final double amount;
  final String status;
  final String date;

  WalletTransaction({
    required this.id,
    required this.details,
    required this.amount,
    required this.status,
    required this.date,
  });
}

class AuditorWalletTransactionScreen extends StatefulWidget {
  const AuditorWalletTransactionScreen({super.key});

  @override
  State<AuditorWalletTransactionScreen> createState() => _AuditorWalletTransactionScreenState();
}

class _AuditorWalletTransactionScreenState extends State<AuditorWalletTransactionScreen> {
  // Set this to false to see the table with data
  final bool _showEmptyState = true; 

  final List<WalletTransaction> _transactions = [
    WalletTransaction(id: 'TXN-9021', details: 'Monthly Cashback', amount: 5000.00, status: 'CREDITED', date: '10/09/2026'),
    WalletTransaction(id: 'TXN-9022', details: 'Referral Bonus', amount: 1000.00, status: 'CREDITED', date: '08/09/2026'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom layout requires no default header
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Perfect for mobile & tablet constraints
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. AVAILABLE BALANCE CARD (Navy with watermark)
                _buildBalanceCard(),
                const SizedBox(height: 24),

                // 2. TOTAL CASHBACK & REFERRAL REWARDS
                _buildStatCard('TOTAL CASHBACK', '₹0'),
                const SizedBox(height: 24),
                _buildStatCard('REFERRAL REWARDS', '₹0'),
                const SizedBox(height: 24),

                // 3. SEARCH AND FILTER SECTION
                _buildSearchAndFilterSection(),
                const SizedBox(height: 24),

                // 4. TRANSACTIONS TABLE
                _buildTransactionTable(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 1. BALANCE CARD
  // ==========================================================================
  Widget _buildBalanceCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.kPrimaryDark, // Deep Navy Blue
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryDark.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Stack(
        children: [
          // Faint Wallet Watermark on the right
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.account_balance_wallet,
              size: 160,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'AVAILABLE BALANCE',
                  style: TextStyle(
                    color: Color(0xFF94A3B8), // Slate Muted
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '₹0.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. STAT CARDS
  // ==========================================================================
  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.kPrimaryDark,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. SEARCH AND FILTER SECTION
  // ==========================================================================
  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            style: const TextStyle(
              color: AppColors.kPrimaryDark,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: 'SEARCH TRANSACTIONS...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kPrimaryDark, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter Dropdown & Refresh Button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.filter_alt_outlined, color: Color(0xFF94A3B8), size: 16),
                      SizedBox(width: 12),
                      Text(
                        'ALL TYPES',
                        style: TextStyle(
                          color: AppColors.kTextDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Refresh Button
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryDark,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.kPrimaryDark.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.sync, color: AppColors.goldColor, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 4. TRANSACTIONS TABLE
  // ==========================================================================
  Widget _buildTransactionTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header Row (Simulated to allow full control over scrolling & empty state)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              // Fixed table width (not just a minWidth) so this doesn't hand an
              // unbounded max-width down to the Column below, which made layout
              // thrash every frame and left the page blank.
              width: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width - 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Row(
                      children: [
                        _buildHeaderCell('ID', width: 100),
                        _buildHeaderCell('DETAILS', width: 150),
                        _buildHeaderCell('AMOUNT', width: 120),
                        _buildHeaderCell('STATUS', width: 100),
                        _buildHeaderCell('DATE', width: 100),
                      ],
                    ),
                  ),

                  // Body (Empty State or Data Rows)
                  if (_showEmptyState || _transactions.isEmpty)
                    _buildEmptyState()
                  else
                    ..._transactions.map((txn) => _buildDataRow(txn)).toList(),
                    
                  const SizedBox(height: 16), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header Cell Helper
  Widget _buildHeaderCell(String title, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          fontSize: 10,
          color: Color(0xFF94A3B8), // Slate 400
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // Data Row Helper
  Widget _buildDataRow(WalletTransaction txn) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              SizedBox(width: 100, child: Text(txn.id, style: _dataStyle(color: AppColors.kPrimaryDark))),
              SizedBox(width: 150, child: Text(txn.details, style: _dataStyle())),
              SizedBox(width: 120, child: Text('₹${txn.amount.toStringAsFixed(2)}', style: _dataStyle(color: AppColors.kPrimaryDark, size: 14))),
              SizedBox(width: 100, child: _buildStatusBadge(txn.status)),
              SizedBox(width: 100, child: Text(txn.date, style: _dataStyle(color: const Color(0xFF94A3B8), size: 10))),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _dataStyle({Color color = AppColors.kTextDark, double size = 12}) {
    return TextStyle(
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      fontSize: size,
      color: color,
    );
  }

  // Status Badge Helper
  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.goldBadgeBg;
    Color text = AppColors.goldColor;

    if (status == 'CREDITED') {
      bg = const Color(0xFFF0FDF4); text = const Color(0xFF16A34A);
    } else if (status == 'PENDING') {
      bg = const Color(0xFFFFFBEB); text = AppColors.goldColor;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(
          status,
          style: TextStyle(color: text, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 9, letterSpacing: 0.5),
        ),
      ),
    );
  }

  // Empty State Helper matching the screenshot
  Widget _buildEmptyState() {
    return SizedBox(
      width: double.infinity,
      height: 300, // Provides ample space to mimic the screenshot's spacing
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.show_chart_rounded, // Pulse / Chart Icon
            size: 64,
            color: Color(0xFFE2E8F0),
          ),
          SizedBox(height: 16),
          Text(
            'NO TRANSACTIONS YET',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}