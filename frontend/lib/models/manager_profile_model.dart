// lib/features/manager/profile/manager_profile_model.dart
import 'package:frontend/core/models/app_user.dart';

class ManagerProfile {
  final String id;
  final String name;
  final String email;
  final String phone;

  const ManagerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  /// Seed the edit form from the already-logged-in session user.
  /// TODO: confirm these field names against your actual AppUser class
  /// (e.g. it might be `fullName` instead of `name`, `mobile` instead of
  /// `phone`, etc). Adjust the getters below if they don't match.
  factory ManagerProfile.fromAppUser(AppUser user) {
    return ManagerProfile(
      id: user.id.toString(),
      name: user.name,
      email: user.email,
      phone: user.phone,
    );
  }

  ManagerProfile copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return ManagerProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}