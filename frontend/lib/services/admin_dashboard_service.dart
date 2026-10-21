import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

class AdminDashboardService {
  Future<AdminDashboardData> fetchDashboard() async {
    try {
      final response = await http
          .get(ApiConfig.endpoint(AdminEndpoints.dashboardStats))
          .timeout(ApiConfig.timeout);
      final body = jsonDecode(response.body);

      if (response.statusCode != 200 ||
          body is! Map ||
          body['status'] != 'success') {
        final message = body is Map ? body['message'] : null;
        throw AdminDashboardException(
          message?.toString() ?? 'Failed to load dashboard data.',
        );
      }

      return AdminDashboardData.fromJson(
        Map<String, dynamic>.from(body['data'] as Map? ?? const {}),
      );
    } on AdminDashboardException {
      rethrow;
    } on FormatException {
      throw const AdminDashboardException('Unexpected response from server.');
    } catch (error) {
      throw AdminDashboardException('Could not reach the server: $error');
    }
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.revenue,
    required this.payouts,
    required this.users,
    required this.newUsersLast24h,
    required this.totalGoldWeight,
    required this.totalSilverWeight,
    required this.revenueHistory,
    required this.userHistory,
    required this.levelDistribution,
    required this.topReferrers,
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      revenue: _toDouble(json['revenue']),
      payouts: _toDouble(json['payouts']),
      users: _toInt(json['users']),
      newUsersLast24h: _toInt(json['node_velocity']),
      totalGoldWeight: _toDouble(json['total_gold_weight']),
      totalSilverWeight: _toDouble(json['total_silver_weight']),
      revenueHistory: _history(json['revenue_history'], 'amount'),
      userHistory: _history(json['user_history'], 'count'),
      levelDistribution: _numberMap(json['level_distribution']),
      topReferrers: (json['top_referrers'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => AdminReferrer.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
    );
  }

  final double revenue;
  final double payouts;
  final int users;
  final int newUsersLast24h;
  final double totalGoldWeight;
  final double totalSilverWeight;
  final List<AdminDashboardPoint> revenueHistory;
  final List<AdminDashboardPoint> userHistory;
  final Map<String, double> levelDistribution;
  final List<AdminReferrer> topReferrers;

  static List<AdminDashboardPoint> _history(Object? value, String valueKey) {
    return (value as List? ?? const [])
        .whereType<Map>()
        .map((row) => AdminDashboardPoint(
              label: row['date']?.toString() ?? '',
              value: _toDouble(row[valueKey]),
            ))
        .toList();
  }

  static Map<String, double> _numberMap(Object? value) {
    final map = value is Map ? value : const {};
    return map.map((key, value) => MapEntry(key.toString(), _toDouble(value)));
  }

  static double _toDouble(Object? value) =>
      double.tryParse(value.toString()) ?? 0;

  static int _toInt(Object? value) => int.tryParse(value.toString()) ?? 0;
}

class AdminDashboardPoint {
  const AdminDashboardPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class AdminReferrer {
  const AdminReferrer({
    required this.name,
    required this.referralCode,
    required this.referrals,
    required this.earnings,
  });

  factory AdminReferrer.fromJson(Map<String, dynamic> json) {
    return AdminReferrer(
      name: json['name']?.toString() ?? 'Unknown investor',
      referralCode: json['referral_code']?.toString() ?? '',
      referrals: int.tryParse(json['referrals']?.toString() ?? '') ?? 0,
      earnings: double.tryParse(json['earnings']?.toString() ?? '') ?? 0,
    );
  }

  final String name;
  final String referralCode;
  final int referrals;
  final double earnings;
}

class AdminDashboardException implements Exception {
  const AdminDashboardException(this.message);

  final String message;

  @override
  String toString() => message;
}
