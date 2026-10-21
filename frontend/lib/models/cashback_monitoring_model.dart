class CashbackMonitoringEntry {
	final int id;
	final String name;
	final String? phone;
	final String? customerCode;
	final double amount;
	final String? walletType;
	final String status;

	const CashbackMonitoringEntry({
		required this.id,
		required this.name,
		required this.amount,
		this.phone,
		this.customerCode,
		this.walletType,
		this.status = 'pending',
	});

	factory CashbackMonitoringEntry.fromJson(Map<String, dynamic> json) {
		return CashbackMonitoringEntry(
			id: _asInt(json['id']),
			name: _asString(json['customer_name']) ??
					_asString(json['name']) ??
					'Unknown customer',
			phone: _asString(json['phone']),
			customerCode: _asString(json['customer_code']),
			amount: _asDouble(json['purchase_amount'] ?? json['amount']),
			walletType: _asString(json['wallet_type']) ?? 'STANDARD WALLET',
			status: _asString(json['status']) ?? 'pending',
		);
	}

	String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

	static int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

	static double _asDouble(dynamic value) {
		if (value is num) return value.toDouble();
		return double.tryParse(value?.toString() ?? '') ?? 0;
	}

	static String? _asString(dynamic value) {
		final text = value?.toString().trim();
		return text == null || text.isEmpty ? null : text;
	}
}

class CashbackMonitoringResult {
	final List<CashbackMonitoringEntry> entries;
	final int count;
	final double totalAmount;

	const CashbackMonitoringResult({
		required this.entries,
		required this.count,
		required this.totalAmount,
	});

	factory CashbackMonitoringResult.fromJson(Map<String, dynamic> json) {
		final rows = (json['data'] as List<dynamic>? ?? [])
				.whereType<Map>()
				.map((row) => CashbackMonitoringEntry.fromJson(
							Map<String, dynamic>.from(row),
						))
				.toList();
		final summary = json['summary'] is Map
				? Map<String, dynamic>.from(json['summary'] as Map)
				: <String, dynamic>{};

		return CashbackMonitoringResult(
			entries: rows,
			count: int.tryParse(summary['count']?.toString() ?? '') ?? rows.length,
			totalAmount: _asDouble(summary['total_amount']) ??
					rows.fold<double>(0, (total, entry) => total + entry.amount),
		);
	}

	static double? _asDouble(dynamic value) {
		if (value is num) return value.toDouble();
		final parsed = double.tryParse(value?.toString() ?? '');
		return parsed;
	}
}
