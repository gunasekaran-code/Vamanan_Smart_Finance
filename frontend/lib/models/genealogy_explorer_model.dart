class GenealogyNode {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? referralCode;
  final DateTime? createdAt;
  final String? kycStatus;
  final double totalInvestment;
  final double totalEarned;
  final int level;
  final bool isRoot;
  final List<GenealogyNode> downline;

  const GenealogyNode({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.referralCode,
    this.createdAt,
    this.kycStatus,
    this.totalInvestment = 0,
    this.totalEarned = 0,
    this.level = 0,
    this.isRoot = false,
    this.downline = const [],
  });

  factory GenealogyNode.fromJson(Map<String, dynamic> json) {
    return GenealogyNode(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      referralCode: json['referral_code']?.toString(),
      createdAt: _parseDate(json['created_at']),
      kycStatus: json['kyc_status']?.toString(),
      totalInvestment: _toDouble(json['total_investment']),
      totalEarned: _toDouble(json['total_earned']),
      level: _toInt(json['level']),
      isRoot: json['is_root'] == true,
      downline: (json['downline'] as List<dynamic>? ?? const [])
          .map((e) => GenealogyNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// Short identifier shown in UI cards — prefers the human referral code,
  /// falls back to the raw database id.
  String get systemId => (referralCode != null && referralCode!.isNotEmpty)
      ? referralCode!
      : id;

  bool get isKycVerified {
    final s = (kycStatus ?? '').toLowerCase();
    return s == 'verified' || s == 'approved';
  }

  bool get isKycPending => !isKycVerified;

  /// Direct referrals only.
  int get directCount => downline.length;

  /// Every descendant in the tree, recursively (not including this node).
  int get totalDownlineCount =>
      downline.fold(0, (sum, child) => sum + 1 + child.totalDownlineCount);

  GenealogyNode copyWith({List<GenealogyNode>? downline}) {
    return GenealogyNode(
      id: id,
      name: name,
      email: email,
      phone: phone,
      referralCode: referralCode,
      createdAt: createdAt,
      kycStatus: kycStatus,
      totalInvestment: totalInvestment,
      totalEarned: totalEarned,
      level: level,
      isRoot: isRoot,
      downline: downline ?? this.downline,
    );
  }
}