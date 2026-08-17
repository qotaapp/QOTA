import 'package:flutter/material.dart';

/// Palette Qota — dérivée du logo fourni (orange chaud sur fond clair,
/// icônes de navigation noires et minimalistes, sans texte sous les icônes).
/// Palette Qota — dérivée du logo officiel (icône fournie par le
/// propriétaire du projet) : dégradé orange sur fond noir profond,
/// avec la bulle de dialogue caractéristique du "Q". Le reste de
/// l'interface (fond clair, icônes noires) suit la direction
/// graphique validée précédemment (§12) et n'est PAS repassé en
/// mode sombre — seules les nouvelles teintes ci-dessous s'ajoutent,
/// utilisées pour l'écran de démarrage et les éléments de marque.
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

  // ---- Palette de marque (logo officiel) ----
  static const Color brandBlack =
      Color(0xFF141414); // fond noir du logo / icône app
  static const Color brandOrangeLight =
      Color(0xFFFFB25C); // haut du dégradé du "Q"
  static const Color brandOrangeDark =
      Color(0xFFE8590C); // bas du dégradé / ombre portée

  static const LinearGradient brandOrangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandOrangeLight, primaryOrange, brandOrangeDark],
    stops: [0.0, 0.55, 1.0],
  );
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
