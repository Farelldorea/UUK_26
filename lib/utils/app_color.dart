import 'package:flutter/material.dart';

class AppColor {
  static const primary = Color(0xFF1565C0);
  static const dark = Color(0xFF0D47A1);
  static const light = Color(0xFF42A5F5);
  static const soft = Color(0xFFE3F2FD);
  static const bg = Color(0xFFF4F8FF);
  static const text = Color(0xFF0B1F3A);
  static const grey = Color(0xFF6B7C93);
  static const available = Color(0xFF1E88E5);
  static const borrowed = Color(0xFF78909C);

  static const gradient = LinearGradient(
    colors: [dark, primary, light],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> shadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}