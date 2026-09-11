import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

// --- Mock Data Model ---
class AuditEntry {
  final String time;
  final String action;
  final String entity;
  final String detail;
  final String amount;
  final String actor;

  AuditEntry({
    required this.time,
    required this.action,
    required this.entity,
    required this.detail,
    required this.amount,
    required this.actor,
  });
}

class AuditLogsViewWidget extends StatefulWidget {
  const AuditLogsViewWidget({super.key});

  @override
  State<AuditLogsViewWidget> createState() => _AuditLogsViewWidgetState();
}

class _AuditLogsViewWidgetState extends State<AuditLogsViewWidget> {
  // Mock Data matching the design image
  final List<AuditEntry> _entries = [
    AuditEntry(
      time: '2026-09-02 15:48:40',
      action: 'export',
      entity: 'Ledger #Inventory',
      detail: 'Exported Inventory Ledger as xml (37 rows)',
      amount: '—',
      actor: 'admin',
    ),
    AuditEntry(
      time: '2026-07-27 10:06:38',
      action: 'export',
      entity: 'Ledger #Inventory',
      detail: 'Exported Inventory Ledger as xml (0 rows)',
      amount: '—',
      actor: 'admin',
    ),
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
                        'AUDIT TRAIL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A), // Navy Blue
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Text(
                      '${_entries.length} ENTRIES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF94A3B8).withOpacity(0.8),
                        letterSpacing: 1,
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
                      DataColumn(label: Text('TIME')),
                      DataColumn(label: Text('ACTION')),
                      DataColumn(label: Text('ENTITY')),
                      DataColumn(label: Text('DETAIL')),
                      DataColumn(label: Text('AMOUNT')),
                      DataColumn(label: Text('ACTOR')),
                    ],
                    rows: _entries.map((entry) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            entry.time, 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 13),
                          )),
                          DataCell(Text(
                            entry.action, 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13),
                          )),
                          DataCell(Text(
                            entry.entity, 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF334155), fontSize: 13),
                          )),
                          DataCell(Text(
                            entry.detail, 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF334155), fontSize: 13),
                          )),
                          DataCell(Text(
                            entry.amount, 
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF334155), fontSize: 13),
                          )),
                          DataCell(Text(
                            entry.actor, 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF334155), fontSize: 13),
                          )),
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