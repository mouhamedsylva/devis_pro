/// Couleurs officielles DevisPro.
///
/// Palette Golden: Gradient linéaire doré élégant.
import 'package:flutter/material.dart';

class AppColors {
  // Gradient doré - 4 nuances
  static const Color golden1 = Color(0xFFDFB555); // Doré intense
  static const Color golden2 = Color(0xFFEAD094); // Doré moyen
  static const Color golden3 = Color(0xFFF4E8CD); // Doré clair
  static const Color golden4 = Color(0xFFD5AD52); // Doré profond

  // Couleurs complémentaires
  static const Color black = Color(0xFF111111);
  static const Color white = Colors.white;
  static const Color bg = Color(0xFFFFFBF5); // Fond légèrement doré
  static const Color danger = Color(0xFFD32F2F);
  
  // Ancien jaune (réservé pour usage futur)
  static const Color yellow = Color(0xFFF9B000);

  // Gradients linéaires
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [golden1, golden2, golden3, golden4],
  );

  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [golden1, golden2],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [golden2, golden1],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [golden3, golden2],
    stops: [0.0, 1.0],
  );

  const AppColors._();
}

