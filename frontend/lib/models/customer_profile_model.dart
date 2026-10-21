/// Models the JSON returned by `api/customer/profile.php`.
///
/// GET /customer/profile.php?user_id=N
///   -> { status, data: { user: {...}, wallet: {balance}, stats: {...} } }
///
/// This is the endpoint the profile page reads, not `get_profile.php` — that
/// one joins a `kyc_details` table which does not exist in this database and
/// fails with "Base table or view not found". profile.php takes
/// `kyc_status`, `aadhar_no` and `pan_no` from the `users` row instead, and
/// throws in the wallet balance and portfolio counters the summary card needs.
class CustomerProfile {
  final int id;
  final String customerId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String referralCode;
  final String avatar;
  final DateTime? createdAt;

  final String kycStatus;
  final String aadharNo;
  final String panNo;

  final String bankName;
  final String accountNo;
  final String ifscCode;

  final double walletBalance;
  final CustomerStats stats;

  const CustomerProfile({
    required this.id,
    this.customerId = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.referralCode = '',
    this.avatar = '',
    this.createdAt,
    this.kycStatus = 'pending',
    this.aadharNo = '',
    this.panNo = '',
    this.bankName = '',
    this.accountNo = '',
    this.ifscCode = '',
    this.walletBalance = 0,
    this.stats = const CustomerStats(),
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    final user = _map(json['user']);
    final wallet = _map(json['wallet']);

    return CustomerProfile(
      id: asInt(user['id']),
      customerId: _str(user['customer_id']),
      name: _str(user['name']),
      email: _str(user['email']),
      phone: _str(user['phone']),
      address: _str(user['address']),
      referralCode: _str(user['referral_code']),
      avatar: _str(user['avatar']),
      createdAt: DateTime.tryParse(_str(user['created_at'])),
      kycStatus: _str(user['kyc_status']).toLowerCase().isEmpty
          ? 'pending'
          : _str(user['kyc_status']).toLowerCase(),
      aadharNo: _str(user['aadhar_no']),
      panNo: _str(user['pan_no']),
      bankName: _str(user['bank_name']),
      accountNo: _str(user['account_no']),
      ifscCode: _str(user['ifsc_code']),
      walletBalance: asDouble(wallet['balance']),
      stats: CustomerStats.fromJson(_map(json['stats'])),
    );
  }

  /// Applied after a successful `update_profile.php` call, which replies with
  /// a message only — re-reading the whole profile just to refresh seven
  /// fields the client already knows would be a wasted round trip.
  CustomerProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? bankName,
    String? accountNo,
    String? ifscCode,
  }) {
    return CustomerProfile(
      id: id,
      customerId: customerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      referralCode: referralCode,
      avatar: avatar,
      createdAt: createdAt,
      kycStatus: kycStatus,
      aadharNo: aadharNo,
      panNo: panNo,
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      ifscCode: ifscCode ?? this.ifscCode,
      walletBalance: walletBalance,
      stats: stats,
    );
  }

  bool get isKycVerified => kycStatus == 'verified';
  bool get hasAadhar => aadharNo.trim().isNotEmpty;
  bool get hasPan => panNo.trim().isNotEmpty;

  /// The two initials the avatar circle falls back to when `avatar` is empty.
  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'[\s.]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  /// Masks all but the last four characters. The full value is already on the
  /// device, but there's no reason to put it on screen in full.
  static String mask(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';
    if (v.length <= 4) return v;
    return '${'•' * (v.length - 4)}${v.substring(v.length - 4)}';
  }

  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : const {};

  static String _str(Object? v) => (v ?? '').toString().trim();

  /// PDO hands numerics back as strings, so never cast — always parse.
  static double asDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString()) ?? 0;
  }

  static int asInt(Object? v) {
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString()) ?? 0;
  }
}

/// The `stats` block — the numbers behind the MY SUMMARY card.
class CustomerStats {
  final int activeCycles;
  final double totalInvested;
  final int referralCount;
  final double totalCashback;
  final double totalReferral;
  final double totalEarned;

  const CustomerStats({
    this.activeCycles = 0,
    this.totalInvested = 0,
    this.referralCount = 0,
    this.totalCashback = 0,
    this.totalReferral = 0,
    this.totalEarned = 0,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      activeCycles: CustomerProfile.asInt(json['active_cycles']),
      totalInvested: CustomerProfile.asDouble(json['total_invested']),
      referralCount: CustomerProfile.asInt(json['referral_count']),
      totalCashback: CustomerProfile.asDouble(json['total_cashback']),
      totalReferral: CustomerProfile.asDouble(json['total_referral']),
      totalEarned: CustomerProfile.asDouble(json['total_earned']),
    );
  }
}

/// One row of the `feedbacks` table, from `customer/get_feedback.php`.
class CustomerFeedback {
  final String id;
  final String subject;
  final String message;
  final int? rating;
  final String fromName;
  final String senderRole;
  final DateTime? createdAt;

  const CustomerFeedback({
    this.id = '',
    this.subject = '',
    this.message = '',
    this.rating,
    this.fromName = '',
    this.senderRole = '',
    this.createdAt,
  });

  factory CustomerFeedback.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    return CustomerFeedback(
      id: (json['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      rating: rawRating == null || rawRating.toString().isEmpty
          ? null
          : CustomerProfile.asInt(rawRating),
      fromName: (json['from_name'] ?? '').toString(),
      senderRole: (json['sender_role'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

/// The two threads `get_feedback.php` returns: what the team sent this
/// customer, and what the customer sent the team.
class CustomerFeedbackThreads {
  final List<CustomerFeedback> received;
  final List<CustomerFeedback> sent;

  const CustomerFeedbackThreads({
    this.received = const [],
    this.sent = const [],
  });

  factory CustomerFeedbackThreads.fromJson(Map<String, dynamic> json) {
    List<CustomerFeedback> parse(Object? raw) => raw is List
        ? raw
            .whereType<Map>()
            .map((e) => CustomerFeedback.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <CustomerFeedback>[];

    return CustomerFeedbackThreads(
      received: parse(json['received']),
      sent: parse(json['sent']),
    );
  }
}
