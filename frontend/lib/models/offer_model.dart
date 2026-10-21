import 'package:flutter/material.dart';

class AppOffer {
  final String id;
  final String title;
  final String details;
  final String category;
  final String? expiryDate; // raw ends_at from backend, null = no expiry
  final Color accentColor;
  final String colorName; // raw backend value, needed when sending updates
  bool isHidden;

  AppOffer({
    required this.id,
    required this.title,
    required this.details,
    required this.category,
    required this.expiryDate,
    required this.accentColor,
    required this.colorName,
    this.isHidden = false,
  });

  factory AppOffer.fromJson(Map<String, dynamic> json) {
    final colorName = (json['color'] ?? 'blue').toString();
    return AppOffer(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      details: (json['message'] ?? '').toString(),
      category: (json['badge'] ?? 'OFFER').toString(),
      expiryDate: json['ends_at']?.toString(),
      accentColor: colorFromName(colorName),
      colorName: colorName,
      isHidden: json['is_active'].toString() == '0',
    );
  }

  static Color colorFromName(String name) {
    switch (name) {
      case 'blue':
        return const Color(0xFF60A5FA);
      case 'amber':
        return const Color(0xFFD97706);
      case 'emerald':
        return const Color(0xFF34D399);
      case 'red':
        return const Color(0xFFFB7185);
      case 'purple':
        return const Color(0xFFC084FC);
      default:
        return const Color(0xFF60A5FA);
    }
  }

  static String nameFromColor(Color color) {
    if (color.value == const Color(0xFF60A5FA).value) return 'blue';
    if (color.value == const Color(0xFFD97706).value) return 'amber';
    if (color.value == const Color(0xFF34D399).value) return 'emerald';
    if (color.value == const Color(0xFFFB7185).value) return 'red';
    if (color.value == const Color(0xFFC084FC).value) return 'purple';
    return 'blue';
  }
}