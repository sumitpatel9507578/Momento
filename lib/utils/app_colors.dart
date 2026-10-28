import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF08080D);
  static const Color surface = Color(0xFF11111A);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color primary = purple;
  static const Color violet = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color pink = Color(0xFFEC4899);

  static const Color white = Colors.white;
  static const Color grey = Color(0xFF9CA3AF);
  static const Color darkGrey = Color(0xFF262631);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, violet, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleCyanGradient = LinearGradient(
    colors: [purple, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
