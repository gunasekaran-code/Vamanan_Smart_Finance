import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/tally_integration_model.dart';
import 'package:frontend/services/tally_integration_service.dart';
import 'tally_state_views.dart';

/// The immutable audit trail (`?resource=audit`) — every export, sync, voucher
/// change and settings save the hub has recorded.
class AuditLogsViewWidget extends StatefulWidget {
  const AuditLogsViewWidget({super.key});

  @override
  State<AuditLogsViewWidget> createState() => _AuditLogsViewWidgetState();
}

class _AuditLogsViewWidgetState extends State<AuditLogsViewWidget> {
  final TallyIntegrationService _service = TallyIntegrationService();

  List<TallyAuditEntry> _entries = const [];
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
      final entries = await _service.fetchAuditLog();
      if (!mounted) return;
      setState(() => _entries = entries);
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
    if (_isLoading && _entries.isEmpty) {
      return const TallyLoadingCard(label: 'LOADING AUDIT TRAIL');
    }
    if (_error != null && _entries.isEmpty) {
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
                        'AUDIT TRAIL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: kTallyNavy,
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
                        color: kTallyMuted.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _isLoading ? null : _load,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kTallyGold),
                            )
                          : const Icon(Icons.refresh, size: 18, color: kTallyGold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.kBorder),

              // --- 2. Scrollable Data Table ---
              if (_entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Text(
                    'NO AUDIT ENTRIES YET',
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
                        DataColumn(label: Text('TIME')),
                        DataColumn(label: Text('ACTION')),
                        DataColumn(label: Text('ENTITY')),
                        DataColumn(label: Text('DETAIL')),
                        DataColumn(label: Text('AMOUNT')),
                        DataColumn(label: Text('ACTOR')),
                      ],
                      rows: _entries.map(_buildRow).toList(),
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

  DataRow _buildRow(TallyAuditEntry entry) {
    const cellStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: Color(0xFF334155),
      fontSize: 13,
    );

    return DataRow(
      cells: [
        DataCell(Text(entry.createdAt,
            style: cellStyle.copyWith(color: kTallyMuted))),
        DataCell(Text(entry.action, style: cellStyle.copyWith(color: kTallyNavy))),
        DataCell(Text(entry.entityDisplay, style: cellStyle)),
        DataCell(
          SizedBox(
            width: 320,
            child: Text(entry.detail, style: cellStyle, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(entry.amountDisplay,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF334155), fontSize: 13))),
        DataCell(Text(entry.actor, style: cellStyle)),
      ],
    );
  }
}
