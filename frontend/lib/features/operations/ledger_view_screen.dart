import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/stat_card.dart';

// --- Mock Data Model ---
class LedgerEntry {
  final String date;
  final String ref;
  final String particulars;
  final String debit;
  final String credit;
  final String status;

  LedgerEntry(this.date, this.ref, this.particulars, this.debit, this.credit, this.status);
}

class LedgerViewWidget extends StatefulWidget {
  const LedgerViewWidget({super.key});

  @override
  State<LedgerViewWidget> createState() => _LedgerViewWidgetState();
}

class _LedgerViewWidgetState extends State<LedgerViewWidget> {
  String _activeLedger = 'INVENTORY LEDGER';
  
  // Date controllers for visual representation
  final TextEditingController _fromDateCtrl = TextEditingController(text: '02/09/2026');
  final TextEditingController _toDateCtrl = TextEditingController(text: '02/09/2026');

  // Mock Ledger Data
  final List<LedgerEntry> _entries = [
    LedgerEntry('2026-08-08', 'VEVP024', 'House Construction — All Construction Mat...', '₹1,80,000.00', '—', 'ACTIVE'),
    LedgerEntry('2026-08-08', 'VEVP007', 'TMT Steel Bars — All Construction Material (...', '₹95,000.00', '—', 'ACTIVE'),
    LedgerEntry('2026-08-07', 'VEVP005', 'Apple iPhone — Electronics (iPhone)', '₹1,00,000.00', '—', 'ACTIVE'),
    LedgerEntry('2026-07-27', 'VEVP001', 'Apple iPhone 16 Pro Max — Electronics (256...', '₹1,49,999.00', '—', 'ACTIVE'),
    LedgerEntry('2026-08-08', 'VEVP012', 'Camera — Electronics (Camera)', '₹65,000.00', '—', 'ACTIVE'),
    LedgerEntry('2026-08-08', 'VEVP014', 'Camera — Electronics (Camera)', '₹4,05,000.00', '—', 'ACTIVE'),
    LedgerEntry('2026-08-08', 'VEVP020', 'Camera Lens — Electronics (Camera Lens)', '₹2,99,000.00', '—', 'ACTIVE'),
    LedgerEntry('2026-08-08', 'VEVP013', 'I Watch Ultra — Electronics (Apple I Watch)', '₹1,20,000.00', '—', 'ACTIVE'),
    LedgerEntry('2026-08-08', 'VEVP017', 'Laptop, Iphone, Ipad pro — Electronics (Lapto...', '₹4,00,000.00', '—', 'ACTIVE'),
  ];

  Future<void> _handleSyncToTally() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'SYNC TO TALLY',
      message: 'Push these vouchers directly into Tally? Make sure TallyPrime is open with the gateway enabled (port 9000).',
      confirmLabel: 'OK',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFFD97706), // Gold/Amber to match button
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Sync Initiated', 
        message: 'Vouchers are being pushed to TallyPrime.', 
        type: ToastType.success
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Ledger Filters & Export Controls ---
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ledger Sub-Tabs
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSubTab('SALES LEDGER', Icons.trending_up),
                  _buildSubTab('CUSTOMER LEDGER', Icons.people_outline),
                  _buildSubTab('CASHBACK LEDGER', Icons.monetization_on_outlined),
                  _buildSubTab('REFERRAL LEDGER', Icons.link),
                  _buildSubTab('WITHDRAWAL LEDGER', Icons.upload_outlined),
                  _buildSubTab('INVENTORY LEDGER', Icons.inventory_2_outlined),
                ],
              ),
              const SizedBox(height: 32),

              // Date Range & Exports (Responsive Wrap)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  // Date Fields
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDateField('FROM', _fromDateCtrl),
                      const SizedBox(width: 12),
                      _buildDateField('TO', _toDateCtrl),
                    ],
                  ),
                  // Apply Button
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFFDE68A)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                  ),
                  
                  // Export Buttons Group
                  Container(
                    height: 48,
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: AppColors.kBorder)),
                    ),
                    margin: const EdgeInsets.only(left: 8, right: 8),
                  ), // Visual divider
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.code, size: 14),
                        label: const Text('XML', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.table_view, size: 14),
                        label: const Text('EXCEL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706), // Gold
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.text_snippet_outlined, size: 14),
                        label: const Text('CSV', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: AppColors.kBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: const Text('PREVIEW', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: AppColors.kBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- 2. Stats & Sync Action Row ---
        LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;
            
            Widget stats = Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: StatCard(
                    label: 'TOTAL STOCK VALUE',
                    value: '₹1,29,54,698.00',
                    icon: Icons.inventory_2_outlined,
                    color: Color(0xFF1E3A8A),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  flex: 1,
                  child: StatCard(
                    label: 'ENTRIES',
                    value: '37',
                    icon: Icons.description_outlined,
                    color: Color(0xFF3B82F6),
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            );

            Widget syncSection = Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('PUSH TO TALLY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleSyncToTally,
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('SYNC INVENTORY LEDGER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706), // Gold
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  stats,
                  const SizedBox(height: 16),
                  syncSection,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: stats),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: syncSection),
              ],
            );
          }
        ),
        const SizedBox(height: 24),

        // --- 3. Ledger Entries Table ---
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('LEDGER ENTRIES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: 1.5)),
                    Text('${_entries.length} RECORD(S)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.kBorder),

              // Horizontally Scrollable Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 48,
                  ),
                  child: DataTable(
                    columnSpacing: 32,
                    headingRowHeight: 56,
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 72,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    dividerThickness: 1,
                    headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 10, letterSpacing: 1.5),
                    columns: const [
                      DataColumn(label: Text('DATE')),
                      DataColumn(label: Text('REF')),
                      DataColumn(label: Text('PARTICULARS')),
                      DataColumn(label: Text('DEBIT')),
                      DataColumn(label: Text('CREDIT')),
                      DataColumn(label: Text('STATUS')),
                    ],
                    rows: _entries.map((entry) {
                      return DataRow(
                        cells: [
                          DataCell(Text(entry.date, style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF64748B), fontSize: 12))),
                          DataCell(Text(entry.ref, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 12))),
                          DataCell(
                            SizedBox(
                              width: 250, // Constrain width for long particulars
                              child: Text(entry.particulars, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          DataCell(Text(entry.debit, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                          DataCell(Text(entry.credit, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFDE68A))),
                              child: Text(entry.status, style: const TextStyle(color: Color(0xFFD97706), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // --- Utility Builders ---

  Widget _buildSubTab(String label, IconData icon) {
    bool isActive = _activeLedger == label;
    return InkWell(
      onTap: () => setState(() => _activeLedger = label),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? const Color(0xFF1E3A8A) : AppColors.kBorder),
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFFFBBF24) : AppColors.kTextMuted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: isActive ? Colors.white : const Color(0xFF1E3A8A))),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 6),
        SizedBox(
          width: 120, // Compact width for dates
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
            decoration: InputDecoration(
              fillColor: const Color(0xFFF8FAFC),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
            ),
          ),
        ),
      ],
    );
  }
}