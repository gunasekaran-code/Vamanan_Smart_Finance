import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/tally_integration_model.dart';
import 'package:frontend/services/tally_integration_service.dart';
import 'tally_state_views.dart';

/// `?resource=reconciliation` — source records against posted vouchers, one
/// row per ledger, so unposted gaps are visible before a sync.
class ReconciliationViewWidget extends StatefulWidget {
  const ReconciliationViewWidget({super.key});

  @override
  State<ReconciliationViewWidget> createState() => _ReconciliationViewWidgetState();
}

class _ReconciliationViewWidgetState extends State<ReconciliationViewWidget> {
  final TallyIntegrationService _service = TallyIntegrationService();

  List<TallyReconciliationRow> _rows = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await _service.fetchReconciliation();
      if (!mounted) return;
      setState(() => _rows = rows);
    } on TallyIntegrationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _rows.isEmpty) {
      return const TallyLoadingCard(label: 'RECONCILING LEDGERS');
    }
    if (_error != null && _rows.isEmpty) {
      return TallyErrorCard(message: _error!, onRetry: _load);
    }

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
                          color: kTallyNavy,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _load,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kTallyGold),
                            )
                          : const Icon(Icons.sync, size: 16, color: kTallyGold),
                      label: const Text(
                        'REFRESH',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: kTallyGold,
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
              if (_rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Text(
                    'NOTHING TO RECONCILE YET',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: kTallyMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 48,
                    ),
                    child: DataTable(
                      columnSpacing: 40,
                      headingRowHeight: 56,
                      dataRowMinHeight: 72,
                      dataRowMaxHeight: 72,
                      headingRowColor: WidgetStateProperty.all(kTallyTint),
                      dividerThickness: 1,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kTallyMuted,
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
                      rows: _rows.map(_buildRow).toList(),
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

  DataRow _buildRow(TallyReconciliationRow row) {
    const cellStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: kTallyNavy,
      fontSize: 13,
    );

    return DataRow(
      cells: [
        DataCell(Text(row.ledgerDisplay, style: cellStyle)),
        DataCell(Text('${row.sourceCount}', style: cellStyle)),
        DataCell(Text(row.sourceAmountDisplay, style: cellStyle)),
        DataCell(Text('${row.postedCount}', style: cellStyle)),
        DataCell(Text('${row.syncedCount}', style: cellStyle)),
        DataCell(Text(
          '${row.unposted}',
          // An outstanding gap is called out in gold; a settled one stays navy.
          style: cellStyle.copyWith(
            color: row.hasUnposted ? kTallyGold : kTallyNavy,
            fontSize: 14,
          ),
        )),
        DataCell(_buildStatusPill(row)),
      ],
    );
  }

  Widget _buildStatusPill(TallyReconciliationRow row) {
    final Color fg = row.isReconciled ? AppColors.kSuccess : kTallyGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Text(
        row.status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
