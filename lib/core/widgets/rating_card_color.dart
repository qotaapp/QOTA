import 'package:flutter/material.dart';

/// Couleur de fond d'une carte publication selon sa note moyenne :
/// - Sans avis : blanc (comportement actuel, inchangé)
/// - 1 à 2.4 : rouge clair
/// - 2.5 à 3.5 : blanc
/// - > 3.5 : or
Color ratingCardColor(double averageScore, int ratingsCount) {
  if (ratingsCount == 0) return Colors.white;
  if (averageScore > 3.5) return const Color(0xFFFFD700); // or
  if (averageScore < 2.5) return const Color(0xFFFFCDD2); // rouge clair
  return Colors.white;
}
