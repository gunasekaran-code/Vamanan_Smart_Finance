/// Result of admin/sync_market_rate.php: a live gold price pulled from
/// an external spot-price API, converted to ₹/gram, with the platform's
/// premium applied and written to platform_settings.
class MarketRateSyncResult {
  final double spotPricePerGram;   // raw international spot, before premium
  final double marketPricePerGram; // spot * platform premium — what's stored
  final DateTime updatedAt;

  MarketRateSyncResult({
    required this.spotPricePerGram,
    required this.marketPricePerGram,
    required this.updatedAt,
  });

  factory MarketRateSyncResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return MarketRateSyncResult(
      spotPricePerGram: double.tryParse('${data['spot_price'] ?? 0}') ?? 0,
      marketPricePerGram: double.tryParse('${data['market_price'] ?? 0}') ?? 0,
      updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class MarketRateException implements Exception {
  final String message;
  MarketRateException(this.message);
  @override
  String toString() => message;
}