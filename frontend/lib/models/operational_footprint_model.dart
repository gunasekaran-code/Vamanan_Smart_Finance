class OperationalFootprintEntry {
  final String type;
  final String title;
  final String description;
  final DateTime? time;

  const OperationalFootprintEntry({
    required this.type,
    required this.title,
    required this.description,
    required this.time,
  });

  factory OperationalFootprintEntry.fromJson(Map<String, dynamic> json) {
    return OperationalFootprintEntry(
      type: json['type']?.toString() ?? 'activity',
      title: json['title']?.toString() ?? 'Activity',
      description: (json['desc'] ?? json['description'] ?? '').toString(),
      time: DateTime.tryParse(json['time']?.toString() ?? ''),
    );
  }
}
