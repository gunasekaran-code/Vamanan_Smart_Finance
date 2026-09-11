import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

// --- Mock Data Model ---
class ReconciliationData {
  final String ledger;
  final String sourceRecords;
  final String sourceAmount;
  final String posted;
  final String synced;
  final String unposted;
  final String status;

  ReconciliationData({
    required this.ledger,
    required this.sourceRecords,
    required this.sourceAmount,
    required this.posted,
    required this.synced,
    required this.unposted,
    required this.status,
  });
}

class ReconciliationViewWidget extends StatefulWidget {
  const ReconciliationViewWidget({super.key});

  @override
  State<ReconciliationViewWidget> createState() => _ReconciliationViewWidgetState();
}

class _ReconciliationViewWidgetState extends State<ReconciliationViewWidget> {
  final List<ReconciliationData> _tableData = [
    ReconciliationData(ledger: 'Sales', sourceRecords: '43', sourceAmount: '₹1,95,36,477.75', posted: '0', synced: '0', unposted: '43', status: 'PENDING'),
    ReconciliationData(ledger: 'Cashback', sourceRecords: '10', sourceAmount: '₹3,09,911.16', posted: '0', synced: '0', unposted: '10', status: 'PENDING'),
    ReconciliationData(ledger: 'Referral', sourceRecords: '7', sourceAmount: '₹55,503.42', posted: '0', synced: '0', unposted: '7', status: 'PENDING'),
    ReconciliationData(ledger: 'Withdrawal', sourceRecords: '0', sourceAmount: '₹0.00', posted: '0', synced: '0', unposted: '0', status: 'RECONCILED'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Header Section ---
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'TRANSACTION RECONCILIATION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A), // Navy Blue
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.sync, size: 16, color: Color(0xFFD97706)),
                      label: const Text(
                        'REFRESH',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Color(0xFFD97706), // Gold/Amber
                          letterSpacing: 1,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.kBorder),

              // --- 2. Scrollable Data Table ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 48, // Fills container width
                  ),
                  child: DataTable(
                    columnSpacing: 40,
                    headingRowHeight: 56,
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 72,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    dividerThickness: 1,
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                    columns: const [
                      DataColumn(label: Text('LEDGER')),
                      DataColumn(label: Text('SOURCE RECORDS'), numeric: true),
                      DataColumn(label: Text('SOURCE AMOUNT'), numeric: true),
                      DataColumn(label: Text('POSTED'), numeric: true),
                      DataColumn(label: Text('SYNCED'), numeric: true),
                      DataColumn(label: Text('UNPOSTED'), numeric: true),
                      DataColumn(label: Text('STATUS')),
                    ],
                    rows: _tableData.map((row) {
                      // Logic for unposted text color
                      bool hasUnposted = int.tryParse(row.unposted) != null && int.parse(row.unposted) > 0;

                      return DataRow(
                        cells: [
                          DataCell(Text(row.ledger, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                          DataCell(Text(row.sourceRecords, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                          DataCell(Text(row.sourceAmount, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                          DataCell(Text(row.posted, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                          DataCell(Text(row.synced, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                          DataCell(Text(row.unposted, style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: hasUnposted ? const Color(0xFFD97706) : const Color(0xFF1E3A8A), fontSize: 14))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB), // Light amber tint
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Text(
                                row.status,
                                style: const TextStyle(
                                  color: Color(0xFFD97706),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Padding at the bottom for aesthetic spacing
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}