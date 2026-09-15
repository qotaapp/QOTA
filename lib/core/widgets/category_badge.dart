// lib/core/widgets/category_badge.dart
import 'package:flutter/material.dart';

/// Badge affichant la catégorie d'une publication, positionné en
/// haut à droite de son image (Feed, Services...).
class CategoryBadge extends StatelessWidget {
  final String label;

  const CategoryBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
