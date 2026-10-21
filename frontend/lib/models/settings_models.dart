import 'dart:convert';

class PlatformSettings {
  final Map<String, String> values;

  const PlatformSettings(this.values);

  String value(String key, [String fallback = '']) => values[key] ?? fallback;

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      json.map((key, value) => MapEntry(key, value?.toString() ?? '')),
    );
  }
}

class SettingsStaff {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;

  const SettingsStaff({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
  });

  factory SettingsStaff.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'];
    final parsedPermissions = rawPermissions is String
      ? (jsonDecode(rawPermissions) is List ? jsonDecode(rawPermissions) as List : const [])
      : rawPermissions;
    return SettingsStaff(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unnamed').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
        permissions: parsedPermissions is List
          ? parsedPermissions.map((item) => item.toString()).toList()
          : const [],
    );
  }
}
