import 'package:flutter/material.dart';

/// Affiche le logo officiel de Qota (fond noir, "Q" en dégradé
/// orange, coins déjà arrondis dans l'image source elle-même) —
/// réutilisable partout où la marque doit apparaître visuellement
/// (écran de connexion, à propos, etc.).
class QotaBrandMark extends StatelessWidget {
  final double size;

  const QotaBrandMark({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
