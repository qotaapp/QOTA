import 'package:flutter/material.dart';

/// Palette Qota — dérivée du logo fourni (orange chaud sur fond clair,
/// icônes de navigation noires et minimalistes, sans texte sous les icônes).
class AppColors {
  AppColors._();

  static const Color primaryOrange = Color(0xFFF15A24); // orange du logo "Qota"
  static const Color background =
      Color(0xFFFAFAF8); // fond quasi blanc, légèrement chaud
  static const Color iconDefault =
      Color(0xFF141414); // icônes noires, style trait épais
  static const Color iconInactive = Color(0xFF9A9A95);
  static const Color surfaceChip =
      Color(0xFFF0EFEC); // fond des bulles (ex: loupe de recherche)
  static const Color textPrimary = Color(0xFF1A1A18);
  static const Color textSecondary = Color(0xFF6F6E69);
  static const Color divider = Color(0xFFE7E5E1);
  static const Color starFilled =
      Color(0xFFF15A24); // l'étoile "Évaluer" reprend l'orange de marque
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOrange,
        primary: AppColors.primaryOrange,
        surface: AppColors.background,
      ),
      fontFamily:
          'Inter', // typo neutre, lisible en FR et compatible diacritiques AR de secours
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.iconDefault),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
      ),
      dividerColor: AppColors.divider,
    );
  }

  // Le thème arabe réutilise la même palette : seule la direction (RTL)
  // change, gérée par Directionality/Localizations, jamais par des couleurs différentes.
}
