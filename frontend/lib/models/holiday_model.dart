class HolidayEntry {
  final String id;
  final DateTime date;
  final String name;
  final String type; // GOVERNMENT, BANK, WEEKEND, OTHER

  HolidayEntry({
    required this.id,
    required this.date,
    required this.name,
    required this.type,
  });

  String get formattedDate =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)}\n${date.year}';

  String get day => _weekday(date.weekday);

  factory HolidayEntry.fromJson(Map<String, dynamic> json) {
    return HolidayEntry(
      id: json['id'].toString(),
      date: DateTime.parse(json['holiday_date'].toString()),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'government').toString().toUpperCase(),
    );
  }

  static String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  static String _weekday(int w) => const [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ][w - 1];
}