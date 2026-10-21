import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

/// Models for the Accounting Hub (`api/admin/tally/`).
///
/// The backend keeps one row shape across every ledger — date, ref,
/// particulars, type, debit, credit, amount, status, meta — so [TallyLedgerRow]
/// is reused for all six ledgers and the exporters stay generic.

// ---------------------------------------------------------------------------
// Shared parsing helpers
// ---------------------------------------------------------------------------

double _toDouble(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
int _toInt(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;
String _toStr(dynamic v) => v?.toString() ?? '';

final NumberFormat _inr =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// `₹1,95,36,477.75` — the Indian grouping used across the hub's cards,
/// tables and totals.
String formatInr(num value) => _inr.format(value);

/// Thrown by `TallyIntegrationService` for anything the UI should surface
/// as a readable message rather than a raw exception.
class TallyIntegrationException implements Exception {
  final String message;
  TallyIntegrationException(this.message);
  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Ledgers
// ---------------------------------------------------------------------------

/// The six ledgers `build_ledger()` knows how to assemble. [wire] is the value
/// the backend expects in `&ledger=`; [label] and [syncLabel] drive the chips
/// and the sync button.
enum TallyLedger {
  sales('sales', 'SALES LEDGER'),
  customer('customer', 'CUSTOMER LEDGER'),
  cashback('cashback', 'CASHBACK LEDGER'),
  referral('referral', 'REFERRAL LEDGER'),
  withdrawal('withdrawal', 'WITHDRAWAL LEDGER'),
  inventory('inventory', 'INVENTORY LEDGER');

  const TallyLedger(this.wire, this.label);
  final String wire;
  final String label;

  /// 'SYNC SALES LEDGER', etc.
  String get syncLabel => 'SYNC $label';

  /// The `summary.label` the backend attaches to this ledger's total. Mirrors
  /// the strings in `_bootstrap.php`, so the CSV recovery path (which carries
  /// rows but no summary) can still name the figure the same way.
  String get totalLabel {
    switch (this) {
      case TallyLedger.sales:
        return 'Net Sales Revenue (excl. GST)';
      case TallyLedger.customer:
        return 'Total Payable to Customers';
      case TallyLedger.cashback:
        return 'Total Cashback Paid';
      case TallyLedger.referral:
        return 'Total Referral Commission';
      case TallyLedger.withdrawal:
        return 'Total Withdrawn';
      case TallyLedger.inventory:
        return 'Total Stock Value';
    }
  }

  static TallyLedger fromWire(String wire) => TallyLedger.values.firstWhere(
        (l) => l.wire == wire,
        orElse: () => TallyLedger.sales,
      );
}

/// File formats `export.php` can emit.
enum TallyExportFormat {
  xml('xml'),
  excel('excel'),
  csv('csv');

  const TallyExportFormat(this.wire);
  final String wire;
}

/// One line in any ledger. `debit`/`credit` are already split by the backend;
/// `amount` is the signed-agnostic magnitude the exporters and sync use.
class TallyLedgerRow {
  final String date;
  final String ref;
  final String particulars;

  /// 'Dr' or 'Cr'.
  final String type;
  final double debit;
  final double credit;
  final double amount;
  final String status;

  /// Ledger-specific extras (email, gst breakup, purity, …). Kept untyped
  /// because each ledger fills it differently.
  final Map<String, dynamic> meta;

  const TallyLedgerRow({
    required this.date,
    required this.ref,
    required this.particulars,
    required this.type,
    required this.debit,
    required this.credit,
    required this.amount,
    required this.status,
    this.meta = const {},
  });

  /// Em dash for a zero side, so the table reads the way an accountant expects.
  String get debitDisplay => debit > 0 ? formatInr(debit) : '—';
  String get creditDisplay => credit > 0 ? formatInr(credit) : '—';
  String get amountDisplay => formatInr(amount);

  factory TallyLedgerRow.fromJson(Map<String, dynamic> json) => TallyLedgerRow(
        date: _toStr(json['date']),
        ref: _toStr(json['ref']),
        particulars: _toStr(json['particulars']),
        type: _toStr(json['type']).isEmpty ? 'Cr' : _toStr(json['type']),
        debit: _toDouble(json['debit']),
        credit: _toDouble(json['credit']),
        amount: _toDouble(json['amount']),
        status: _toStr(json['status']),
        meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

/// The `summary` block every ledger returns. Only the sales ledger fills the
/// GST fields; the rest leave them null.
class TallyLedgerSummary {
  final int count;
  final double total;

  /// e.g. 'Total Stock Value' — the backend's own name for [total].
  final String label;
  final double? gstCollected;
  final double? cgst;
  final double? sgst;
  final double? grossInvoice;

  const TallyLedgerSummary({
    required this.count,
    required this.total,
    required this.label,
    this.gstCollected,
    this.cgst,
    this.sgst,
    this.grossInvoice,
  });

  static const empty = TallyLedgerSummary(count: 0, total: 0, label: 'Total');

  bool get hasGst => (gstCollected ?? 0) > 0;
  String get totalDisplay => formatInr(total);

  factory TallyLedgerSummary.fromJson(Map<String, dynamic> json) =>
      TallyLedgerSummary(
        count: _toInt(json['count']),
        total: _toDouble(json['total']),
        label: _toStr(json['label']).isEmpty ? 'Total' : _toStr(json['label']),
        gstCollected: json['gst_collected'] == null
            ? null
            : _toDouble(json['gst_collected']),
        cgst: json['cgst'] == null ? null : _toDouble(json['cgst']),
        sgst: json['sgst'] == null ? null : _toDouble(json['sgst']),
        grossInvoice: json['gross_invoice'] == null
            ? null
            : _toDouble(json['gross_invoice']),
      );
}

/// `?resource=ledger` — rows plus their summary.
class TallyLedgerResult {
  final TallyLedger ledger;
  final List<TallyLedgerRow> rows;
  final TallyLedgerSummary summary;

  const TallyLedgerResult({
    required this.ledger,
    required this.rows,
    required this.summary,
  });

  factory TallyLedgerResult.fromJson(
    Map<String, dynamic> json, {
    required TallyLedger ledger,
  }) =>
      TallyLedgerResult(
        ledger: ledger,
        rows: (json['data'] as List? ?? const [])
            .map((e) =>
                TallyLedgerRow.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        summary: TallyLedgerSummary.fromJson(
          (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );

  /// Rebuilds a ledger from `export.php&format=csv`.
  ///
  /// `data.php` serialises with a bare `json_encode()`, which returns `false`
  /// — and so writes an empty 200 — the moment any row carries a byte that is
  /// not valid UTF-8. The cashback, referral and inventory ledgers currently
  /// trip that. `build_csv()` walks the same `build_ledger()` rows but echoes
  /// raw bytes, so the CSV export still carries the full ledger; the service
  /// falls back to it and we reassemble the rows here.
  ///
  /// Columns, from `build_csv()`:
  ///   Date, Reference, Particulars, Type, Debit, Credit, Status
  /// with CGST, SGST, GST Rate %, Invoice Total spliced in before Status when
  /// the rows carry GST meta (the sales ledger).
  factory TallyLedgerResult.fromCsv(
    String csv, {
    required TallyLedger ledger,
  }) {
    // Delimiter is fixed (`fputcsv` defaults) and every field stays a String,
    // so amounts are parsed by `_toDouble` rather than guessed at.
    final table = Csv(autoDetect: false, dynamicTyping: false)
        .decode(csv.replaceAll('\r\n', '\n').trim());
    if (table.isEmpty) {
      return TallyLedgerResult(
        ledger: ledger,
        rows: const [],
        summary:
            TallyLedgerSummary(count: 0, total: 0, label: ledger.totalLabel),
      );
    }

    // Index by header name — the GST columns shift Status right on the sales
    // ledger, so fixed positions would read the wrong cell.
    final header = table.first.map((c) => '$c'.trim().toLowerCase()).toList();
    int col(String name) => header.indexOf(name.toLowerCase());

    final iDate = col('Date');
    final iRef = col('Reference');
    final iParticulars = col('Particulars');
    final iType = col('Type');
    final iDebit = col('Debit');
    final iCredit = col('Credit');
    final iStatus = col('Status');
    final iCgst = col('CGST');
    final iSgst = col('SGST');
    final iGstRate = col('GST Rate %');
    final iTotal = col('Invoice Total');

    final rows = <TallyLedgerRow>[];
    var total = 0.0;
    var gstCollected = 0.0;
    var cgstTotal = 0.0;
    var sgstTotal = 0.0;
    var grossInvoice = 0.0;

    for (final raw in table.skip(1)) {
      String cell(int index) =>
          index >= 0 && index < raw.length ? '${raw[index]}'.trim() : '';

      final debit = _toDouble(cell(iDebit));
      final credit = _toDouble(cell(iCredit));
      // Every build_ledger() row books to exactly one side and sets
      // `amount` to that side, so the non-zero column is the amount.
      final amount = debit > 0 ? debit : credit;
      total += amount;

      final meta = <String, dynamic>{};
      if (iCgst >= 0) {
        final cgst = _toDouble(cell(iCgst));
        final sgst = _toDouble(cell(iSgst));
        final invoiceTotal = _toDouble(cell(iTotal));
        cgstTotal += cgst;
        sgstTotal += sgst;
        gstCollected += cgst + sgst;
        grossInvoice += invoiceTotal;
        meta.addAll({
          'cgst': cgst,
          'sgst': sgst,
          'gst': cgst + sgst,
          'gst_rate': _toDouble(cell(iGstRate)),
          'total': invoiceTotal,
          'taxable': amount,
        });
      }

      rows.add(TallyLedgerRow(
        date: cell(iDate),
        ref: cell(iRef),
        particulars: cell(iParticulars),
        type: cell(iType).isEmpty ? (debit > 0 ? 'Dr' : 'Cr') : cell(iType),
        debit: debit,
        credit: credit,
        amount: amount,
        status: cell(iStatus),
        meta: meta,
      ));
    }

    return TallyLedgerResult(
      ledger: ledger,
      rows: rows,
      summary: TallyLedgerSummary(
        count: rows.length,
        total: total,
        label: ledger.totalLabel,
        gstCollected: iCgst >= 0 ? gstCollected : null,
        cgst: iCgst >= 0 ? cgstTotal : null,
        sgst: iCgst >= 0 ? sgstTotal : null,
        grossInvoice: iCgst >= 0 ? grossInvoice : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

/// Headline money figures. `netPosition` is the backend's
/// sales − cashback − referral − withdrawn.
class TallyMetrics {
  final double salesRevenue;
  final double cashbackPaid;
  final double referralPaid;
  final double withdrawn;
  final double inventoryValue;
  final double customerPayable;
  final double netPosition;

  const TallyMetrics({
    this.salesRevenue = 0,
    this.cashbackPaid = 0,
    this.referralPaid = 0,
    this.withdrawn = 0,
    this.inventoryValue = 0,
    this.customerPayable = 0,
    this.netPosition = 0,
  });

  factory TallyMetrics.fromJson(Map<String, dynamic> json) => TallyMetrics(
        salesRevenue: _toDouble(json['sales_revenue']),
        cashbackPaid: _toDouble(json['cashback_paid']),
        referralPaid: _toDouble(json['referral_paid']),
        withdrawn: _toDouble(json['withdrawn']),
        inventoryValue: _toDouble(json['inventory_value']),
        customerPayable: _toDouble(json['customer_payable']),
        netPosition: _toDouble(json['net_position']),
      );
}

/// The integration-status counters on the dashboard.
class TallyCounts {
  final int vouchers;
  final int synced;
  final int pendingSync;
  final int syncRuns;
  final int auditEntries;

  const TallyCounts({
    this.vouchers = 0,
    this.synced = 0,
    this.pendingSync = 0,
    this.syncRuns = 0,
    this.auditEntries = 0,
  });

  factory TallyCounts.fromJson(Map<String, dynamic> json) => TallyCounts(
        vouchers: _toInt(json['vouchers']),
        synced: _toInt(json['synced']),
        pendingSync: _toInt(json['pending_sync']),
        syncRuns: _toInt(json['sync_runs']),
        auditEntries: _toInt(json['audit_entries']),
      );
}

/// One bar of the 6-month revenue trend.
class TallyTrendPoint {
  final String month; // 'APR'
  final double amount;

  const TallyTrendPoint({required this.month, required this.amount});

  factory TallyTrendPoint.fromJson(Map<String, dynamic> json) =>
      TallyTrendPoint(
        month: _toStr(json['month']).toUpperCase(),
        amount: _toDouble(json['amount']),
      );
}

/// `?resource=dashboard`.
class TallyDashboard {
  final TallyMetrics metrics;
  final TallyCounts counts;
  final List<TallyTrendPoint> trend;
  final TallySettings settings;

  const TallyDashboard({
    required this.metrics,
    required this.counts,
    required this.trend,
    required this.settings,
  });

  /// Tallest bar in the trend, so the chart can scale to it. Zero when the
  /// period has no revenue at all — callers must guard the division.
  double get trendPeak =>
      trend.fold<double>(0, (max, p) => p.amount > max ? p.amount : max);

  factory TallyDashboard.fromJson(Map<String, dynamic> json) => TallyDashboard(
        metrics: TallyMetrics.fromJson(
            (json['metrics'] as Map?)?.cast<String, dynamic>() ?? const {}),
        counts: TallyCounts.fromJson(
            (json['counts'] as Map?)?.cast<String, dynamic>() ?? const {}),
        trend: (json['trend'] as List? ?? const [])
            .map((e) =>
                TallyTrendPoint.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        settings: TallySettings.fromJson(
            (json['settings'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

// ---------------------------------------------------------------------------
// Reports — P&L and Balance Sheet
// ---------------------------------------------------------------------------

/// A single `{particulars, amount}` line in either report.
class TallyReportLine {
  final String particulars;
  final double amount;

  const TallyReportLine({required this.particulars, required this.amount});

  String get amountDisplay => formatInr(amount);

  factory TallyReportLine.fromJson(Map<String, dynamic> json) =>
      TallyReportLine(
        particulars: _toStr(json['particulars']),
        amount: _toDouble(json['amount']),
      );

  static List<TallyReportLine> listFrom(dynamic raw) => (raw as List? ??
          const [])
      .map((e) => TallyReportLine.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

/// `?resource=report&report=pnl`. GST collected is reported separately because
/// output tax is a liability, not income.
class TallyPnlReport {
  final String periodStart;
  final String periodEnd;
  final List<TallyReportLine> income;
  final List<TallyReportLine> expenses;
  final double totalIncome;
  final double totalExpense;
  final double netProfit;
  final double margin;
  final double gstCollected;
  final double gstCgst;
  final double gstSgst;

  const TallyPnlReport({
    this.periodStart = '',
    this.periodEnd = '',
    this.income = const [],
    this.expenses = const [],
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.netProfit = 0,
    this.margin = 0,
    this.gstCollected = 0,
    this.gstCgst = 0,
    this.gstSgst = 0,
  });

  /// 'NET PROFIT (98.07%)' — the margin already comes rounded to 2dp.
  String get netProfitLabel => 'NET PROFIT (${margin.toStringAsFixed(2)}%)';

  factory TallyPnlReport.fromJson(Map<String, dynamic> json) {
    final period =
        (json['period'] as Map?)?.cast<String, dynamic>() ?? const {};
    return TallyPnlReport(
      periodStart: _toStr(period['start']),
      periodEnd: _toStr(period['end']),
      income: TallyReportLine.listFrom(json['income']),
      expenses: TallyReportLine.listFrom(json['expenses']),
      totalIncome: _toDouble(json['total_income']),
      totalExpense: _toDouble(json['total_expense']),
      netProfit: _toDouble(json['net_profit']),
      margin: _toDouble(json['margin']),
      gstCollected: _toDouble(json['gst_collected']),
      gstCgst: _toDouble(json['gst_cgst']),
      gstSgst: _toDouble(json['gst_sgst']),
    );
  }
}

/// `?resource=report&report=balance_sheet`. Equity is the balancing figure, so
/// the backend always reports the two sides as equal.
class TallyBalanceSheet {
  final String asOn;
  final List<TallyReportLine> assets;
  final List<TallyReportLine> liabilities;
  final double totalAssets;
  final double totalLiabilities;
  final double equity;
  final bool balanced;

  const TallyBalanceSheet({
    this.asOn = '',
    this.assets = const [],
    this.liabilities = const [],
    this.totalAssets = 0,
    this.totalLiabilities = 0,
    this.equity = 0,
    this.balanced = true,
  });

  factory TallyBalanceSheet.fromJson(Map<String, dynamic> json) =>
      TallyBalanceSheet(
        asOn: _toStr(json['as_on']),
        assets: TallyReportLine.listFrom(json['assets']),
        liabilities: TallyReportLine.listFrom(json['liabilities']),
        totalAssets: _toDouble(json['total_assets']),
        totalLiabilities: _toDouble(json['total_liabilities']),
        equity: _toDouble(json['equity']),
        balanced: json['balanced'] == true,
      );
}

// ---------------------------------------------------------------------------
// Vouchers
// ---------------------------------------------------------------------------

/// A row of `tally_vouchers`. `syncStatus` walks draft → posted → synced,
/// with 'error' for a failed push.
class TallyVoucher {
  final int id;
  final String voucherNo;
  final String voucherType;
  final String voucherDate;
  final String partyLedger;
  final String debitLedger;
  final String creditLedger;
  final double amount;
  final String narration;
  final String reference;
  final String source;
  final String syncStatus;
  final String? tallyGuid;
  final String? createdBy;

  const TallyVoucher({
    required this.id,
    required this.voucherNo,
    required this.voucherType,
    required this.voucherDate,
    this.partyLedger = '',
    this.debitLedger = '',
    this.creditLedger = '',
    this.amount = 0,
    this.narration = '',
    this.reference = '',
    this.source = 'manual',
    this.syncStatus = 'draft',
    this.tallyGuid,
    this.createdBy,
  });

  bool get isDraft => syncStatus == 'draft';
  bool get isSynced => syncStatus == 'synced';
  String get amountDisplay => formatInr(amount);

  factory TallyVoucher.fromJson(Map<String, dynamic> json) => TallyVoucher(
        id: _toInt(json['id']),
        voucherNo: _toStr(json['voucher_no']),
        voucherType: _toStr(json['voucher_type']),
        voucherDate: _toStr(json['voucher_date']),
        partyLedger: _toStr(json['party_ledger']),
        debitLedger: _toStr(json['debit_ledger']),
        creditLedger: _toStr(json['credit_ledger']),
        amount: _toDouble(json['amount']),
        narration: _toStr(json['narration']),
        reference: _toStr(json['reference']),
        source:
            _toStr(json['source']).isEmpty ? 'manual' : _toStr(json['source']),
        syncStatus: _toStr(json['sync_status']).isEmpty
            ? 'draft'
            : _toStr(json['sync_status']),
        tallyGuid: json['tally_guid']?.toString(),
        createdBy: json['created_by']?.toString(),
      );
}

/// The voucher types `tally_vouchers.voucher_type` accepts.
const List<String> kTallyVoucherTypes = [
  'Sales',
  'Purchase',
  'Receipt',
  'Payment',
  'Journal',
  'Contra',
  'Credit Note',
  'Debit Note',
];

/// What a create/update sends to `vouchers.php`. Every field is optional on the
/// backend, so the defaults here mirror its own fallbacks.
class TallyVoucherDraft {
  final int? id;
  final String voucherNo;
  final String voucherType;
  final String voucherDate;
  final String partyLedger;
  final String debitLedger;
  final String creditLedger;
  final double amount;
  final String narration;
  final String reference;
  final String source;

  const TallyVoucherDraft({
    this.id,
    this.voucherNo = '',
    this.voucherType = 'Journal',
    required this.voucherDate,
    this.partyLedger = '',
    this.debitLedger = '',
    this.creditLedger = '',
    this.amount = 0,
    this.narration = '',
    this.reference = '',
    this.source = 'manual',
  });

  factory TallyVoucherDraft.fromVoucher(TallyVoucher v) => TallyVoucherDraft(
        id: v.id,
        voucherNo: v.voucherNo,
        voucherType: v.voucherType,
        voucherDate: v.voucherDate,
        partyLedger: v.partyLedger,
        debitLedger: v.debitLedger,
        creditLedger: v.creditLedger,
        amount: v.amount,
        narration: v.narration,
        reference: v.reference,
        source: v.source,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (voucherNo.trim().isNotEmpty) 'voucher_no': voucherNo.trim(),
        'voucher_type': voucherType,
        'voucher_date': voucherDate,
        'party_ledger': partyLedger,
        'debit_ledger': debitLedger,
        'credit_ledger': creditLedger,
        'amount': amount,
        'narration': narration,
        'reference': reference,
        'source': source,
      };
}

/// `?resource=vouchers` — the list plus its count/total.
class TallyVoucherResult {
  final List<TallyVoucher> vouchers;
  final int count;
  final double total;

  const TallyVoucherResult({
    this.vouchers = const [],
    this.count = 0,
    this.total = 0,
  });

  String get totalDisplay => formatInr(total);

  /// '12 VOUCHERS · ₹4,05,000.00' — the subtitle on the management card.
  String get headline =>
      '$count VOUCHER${count == 1 ? '' : 'S'} · $totalDisplay';

  factory TallyVoucherResult.fromJson(Map<String, dynamic> json) {
    final summary =
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    return TallyVoucherResult(
      vouchers: (json['data'] as List? ?? const [])
          .map((e) => TallyVoucher.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      count: _toInt(summary['count']),
      total: _toDouble(summary['total']),
    );
  }
}

// ---------------------------------------------------------------------------
// Audit trail, sync log, reconciliation
// ---------------------------------------------------------------------------

/// A row of `tally_audit_log`. `amount` is null for actions that don't move
/// money (an export, a settings save).
class TallyAuditEntry {
  final int id;
  final String action;
  final String entity;
  final String? entityId;
  final String detail;
  final double? amount;
  final String actor;
  final String createdAt;

  const TallyAuditEntry({
    required this.id,
    required this.action,
    required this.entity,
    this.entityId,
    this.detail = '',
    this.amount,
    this.actor = 'system',
    this.createdAt = '',
  });

  /// 'Ledger #Inventory' — entity with its id, the way the table shows it.
  String get entityDisplay =>
      entityId == null || entityId!.isEmpty ? entity : '$entity #$entityId';

  String get amountDisplay => amount == null ? '—' : formatInr(amount!);

  factory TallyAuditEntry.fromJson(Map<String, dynamic> json) =>
      TallyAuditEntry(
        id: _toInt(json['id']),
        action: _toStr(json['action']),
        entity: _toStr(json['entity']),
        entityId: json['entity_id']?.toString(),
        detail: _toStr(json['detail']),
        amount: json['amount'] == null ? null : _toDouble(json['amount']),
        actor: _toStr(json['actor']).isEmpty ? 'system' : _toStr(json['actor']),
        createdAt: _toStr(json['created_at']),
      );
}

/// A row of `tally_sync_log` — one push attempt at the Tally gateway.
class TallySyncLogEntry {
  final int id;
  final String resource;
  final String gateway;
  final int records;
  final int? created;
  final int? altered;
  final int? errors;
  final double amount;
  final String status; // success | partial | error
  final String message;
  final String createdAt;

  const TallySyncLogEntry({
    required this.id,
    required this.resource,
    this.gateway = '',
    this.records = 0,
    this.created,
    this.altered,
    this.errors,
    this.amount = 0,
    this.status = 'success',
    this.message = '',
    this.createdAt = '',
  });

  factory TallySyncLogEntry.fromJson(Map<String, dynamic> json) =>
      TallySyncLogEntry(
        id: _toInt(json['id']),
        resource: _toStr(json['resource']),
        gateway: _toStr(json['gateway']),
        records: _toInt(json['records']),
        created: json['created'] == null ? null : _toInt(json['created']),
        altered: json['altered'] == null ? null : _toInt(json['altered']),
        errors: json['errors'] == null ? null : _toInt(json['errors']),
        amount: _toDouble(json['amount']),
        status: _toStr(json['status']),
        message: _toStr(json['message']),
        createdAt: _toStr(json['created_at']),
      );
}

/// `?resource=reconciliation` — source records against posted vouchers, per
/// ledger. `unposted` is source minus posted.
class TallyReconciliationRow {
  final String ledger;
  final int sourceCount;
  final double sourceAmount;
  final int postedCount;
  final double postedAmount;
  final int syncedCount;
  final int unposted;
  final String status; // reconciled | pending

  const TallyReconciliationRow({
    required this.ledger,
    this.sourceCount = 0,
    this.sourceAmount = 0,
    this.postedCount = 0,
    this.postedAmount = 0,
    this.syncedCount = 0,
    this.unposted = 0,
    this.status = 'pending',
  });

  bool get isReconciled => status == 'reconciled';
  bool get hasUnposted => unposted > 0;

  /// 'Sales', 'Cashback' — the backend sends the wire name lowercased.
  String get ledgerDisplay =>
      ledger.isEmpty ? ledger : ledger[0].toUpperCase() + ledger.substring(1);

  String get sourceAmountDisplay => formatInr(sourceAmount);

  factory TallyReconciliationRow.fromJson(Map<String, dynamic> json) =>
      TallyReconciliationRow(
        ledger: _toStr(json['ledger']),
        sourceCount: _toInt(json['source_count']),
        sourceAmount: _toDouble(json['source_amount']),
        postedCount: _toInt(json['posted_count']),
        postedAmount: _toDouble(json['posted_amount']),
        syncedCount: _toInt(json['synced_count']),
        unposted: _toInt(json['unposted']),
        status: _toStr(json['status']),
      );
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

/// The ten keys `tally_settings` persists. Defaults match the backend's own,
/// so a fresh install renders the same values the API would return.
class TallySettings {
  final String company;
  final String gateway;
  final String salesLedger;
  final String cgstLedger;
  final String sgstLedger;
  final String cashbackLedger;
  final String referralLedger;
  final String bankLedger;
  final String debtorsGroup;
  final String inventoryGroup;

  const TallySettings({
    this.company = '',
    this.gateway = 'http://localhost:9000',
    this.salesLedger = 'Sales Account',
    this.cgstLedger = 'Output CGST',
    this.sgstLedger = 'Output SGST',
    this.cashbackLedger = 'Cashback Expense',
    this.referralLedger = 'Referral Commission',
    this.bankLedger = 'Bank Account',
    this.debtorsGroup = 'Sundry Debtors',
    this.inventoryGroup = 'Gold Stock',
  });

  factory TallySettings.fromJson(Map<String, dynamic> json) {
    const fallback = TallySettings();
    String pick(String key, String orElse) {
      final v = json[key]?.toString();
      return (v == null || v.isEmpty) ? orElse : v;
    }

    return TallySettings(
      // Company is legitimately blank ("use whatever company is open"), so it
      // is the one field that must not fall back to a default.
      company: json['company']?.toString() ?? '',
      gateway: pick('gateway', fallback.gateway),
      salesLedger: pick('sales_ledger', fallback.salesLedger),
      cgstLedger: pick('cgst_ledger', fallback.cgstLedger),
      sgstLedger: pick('sgst_ledger', fallback.sgstLedger),
      cashbackLedger: pick('cashback_ledger', fallback.cashbackLedger),
      referralLedger: pick('referral_ledger', fallback.referralLedger),
      bankLedger: pick('bank_ledger', fallback.bankLedger),
      debtorsGroup: pick('debtors_group', fallback.debtorsGroup),
      inventoryGroup: pick('inventory_group', fallback.inventoryGroup),
    );
  }

  Map<String, dynamic> toJson() => {
        'company': company,
        'gateway': gateway,
        'sales_ledger': salesLedger,
        'cgst_ledger': cgstLedger,
        'sgst_ledger': sgstLedger,
        'cashback_ledger': cashbackLedger,
        'referral_ledger': referralLedger,
        'bank_ledger': bankLedger,
        'debtors_group': debtorsGroup,
        'inventory_group': inventoryGroup,
      };
}

// ---------------------------------------------------------------------------
// Sync result
// ---------------------------------------------------------------------------

/// What `sync.php` replies with. 'offline' is not a failure — Tally was simply
/// unreachable, and the vouchers are still there to export and import by hand.
class TallySyncResult {
  final String status; // success | offline | error
  final String message;
  final int? created;
  final int? altered;
  final int? errors;
  final int records;
  final double amount;

  const TallySyncResult({
    required this.status,
    required this.message,
    this.created,
    this.altered,
    this.errors,
    this.records = 0,
    this.amount = 0,
  });

  bool get isSuccess => status == 'success';
  bool get isOffline => status == 'offline';

  factory TallySyncResult.fromJson(Map<String, dynamic> json) =>
      TallySyncResult(
        status:
            _toStr(json['status']).isEmpty ? 'error' : _toStr(json['status']),
        message: _toStr(json['message']),
        created: json['created'] == null ? null : _toInt(json['created']),
        altered: json['altered'] == null ? null : _toInt(json['altered']),
        errors: json['errors'] == null ? null : _toInt(json['errors']),
        records: _toInt(json['records']),
        amount: _toDouble(json['amount']),
      );
}
