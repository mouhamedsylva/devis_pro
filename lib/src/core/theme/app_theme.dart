/// Thème DevisPro: simple, lisible, gros boutons, compatible bas de gamme.
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.yellow,
        primary: AppColors.yellow,
        secondary: AppColors.black,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: Color(0xFFF7F7F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.black,
        centerTitle: true,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.black,
        displayColor: AppColors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.black,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  const AppTheme._();
}

