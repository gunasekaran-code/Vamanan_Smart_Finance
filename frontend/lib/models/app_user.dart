import 'user_role.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  /// Handy once a real API is wired up — build an AppUser straight from
  /// a JSON login/profile response.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['full_name'] ?? 'User').toString(),
      email: (json['email'] ?? '').toString(),
      role: UserRole.fromApiValue((json['role'] ?? 'CUSTOMER').toString()),
    );
  }
}
