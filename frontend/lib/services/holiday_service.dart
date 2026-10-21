import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/models/holiday_model.dart';

class HolidayService {
  HolidayService._();
  static final HolidayService instance = HolidayService._();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<HolidayEntry>> fetchHolidays() async {
    final res = await http
        .get(ApiConfig.endpoint(HolidayEndpoints.holidays), headers: _headers)
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to load holidays (${res.statusCode})');
    }
    final List data = body['data'] ?? [];
    return data.map((e) => HolidayEntry.fromJson(e)).toList();
  }

  Future<void> addHoliday({
    required DateTime date,
    required String name,
    required String type,
  }) async {
    final res = await http
        .post(
          ApiConfig.endpoint(HolidayEndpoints.holidays),
          headers: _headers,
          body: jsonEncode({
            'date': _isoDate(date),
            'name': name,
            'type': type.toLowerCase(),
          }),
        )
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to save holiday (${res.statusCode})');
    }
  }

  Future<void> deleteHoliday(String id) async {
    final res = await http
        .post(
          ApiConfig.endpoint(HolidayEndpoints.holidays),
          headers: _headers,
          body: jsonEncode({'action': 'delete', 'id': id}),
        )
        .timeout(ApiConfig.timeout);

    final body = jsonDecode(res.body);
    if (res.statusCode != 200 || body['status'] != 'success') {
      throw Exception(body['message'] ?? 'Failed to delete holiday (${res.statusCode})');
    }
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}