class WalletOverview {
  final double balance;
  final double totalInvested;
  final double cashbackEarnings;
  final double referralEarnings;
  final double pendingPayouts;

  const WalletOverview({
    required this.balance,
    required this.totalInvested,
    required this.cashbackEarnings,
    required this.referralEarnings,
    required this.pendingPayouts,
  });

  factory WalletOverview.empty() => const WalletOverview(
        balance: 0,
        totalInvested: 0,
        cashbackEarnings: 0,
        referralEarnings: 0,
        pendingPayouts: 0,
      );

  factory WalletOverview.fromJson(Map<String, dynamic> json) => WalletOverview(
        balance: _number(json['balance']),
        totalInvested: _number(json['investment_total']),
        cashbackEarnings: _number(json['cashback_total']),
        referralEarnings: _number(json['referral_total']),
        pendingPayouts: _number(json['pending_withdrawal']),
      );
}

class WalletTransactionRecord {
  final String id;
  final String type;
  final String category;
  final double amount;
  final String status;
  final String description;
  final DateTime? date;

  const WalletTransactionRecord({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.status,
    required this.description,
    required this.date,
  });

  factory WalletTransactionRecord.fromJson(Map<String, dynamic> json) =>
      WalletTransactionRecord(
        id: (json['id'] ?? '—').toString(),
        type: (json['type'] ?? '').toString().toUpperCase(),
        category: (json['category'] ?? 'other').toString(),
        amount: _number(json['amount']),
        status: (json['status'] ?? 'pending').toString().toUpperCase(),
        description: (json['description'] ?? '').toString(),
        date: DateTime.tryParse((json['created_at'] ?? '').toString()),
      );
}

class WithdrawalRecord {
  final String id;
  final double amount;
  final String bank;
  final String status;
  final DateTime? date;

  const WithdrawalRecord({
    required this.id,
    required this.amount,
    required this.bank,
    required this.status,
    required this.date,
  });

  factory WithdrawalRecord.fromTransaction(
          WalletTransactionRecord transaction) =>
      WithdrawalRecord(
        id: transaction.id,
        amount: transaction.amount,
        bank: transaction.description.isEmpty
            ? 'Registered bank account'
            : transaction.description,
        status: transaction.status,
        date: transaction.date,
      );

  factory WithdrawalRecord.fromJson(Map<String, dynamic> json) =>
      WithdrawalRecord(
        id: (json['id'] ?? '—').toString(),
        amount: _number(json['amount']),
        bank: (json['bank_details'] ?? 'Registered bank account').toString(),
        status: (json['status'] ?? 'pending').toString().toUpperCase(),
        date: DateTime.tryParse((json['created_at'] ?? '').toString()),
      );
}

class WalletSnapshot {
  final WalletOverview overview;
  final List<WalletTransactionRecord> transactions;

  const WalletSnapshot({required this.overview, required this.transactions});

  factory WalletSnapshot.fromJson(Map<String, dynamic> json) {
    final rawTransactions = json['transactions'];
    final transactions = rawTransactions is List
        ? rawTransactions
            .whereType<Map>()
            .map((item) =>
                WalletTransactionRecord.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <WalletTransactionRecord>[];
    return WalletSnapshot(
      overview: WalletOverview.fromJson(json),
      transactions: transactions,
    );
  }
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
