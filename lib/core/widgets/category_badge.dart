// lib/core/widgets/category_badge.dart
import 'package:flutter/material.dart';
import 'icon_resolver.dart';

/// Badge affichant la catégorie d'une publication, positionné en
/// haut à droite de son image (Feed, Services...).
///
/// Affiche une icône plutôt que le texte de la catégorie. `label`
/// reste requis (inchangé pour les appelants existants) mais sert
/// désormais uniquement à l'accessibilité (lecteur d'écran) via
/// `Semantics`, plus à l'affichage visuel.
///
/// `iconValue` (optionnel) : nom d'icône venant de la base
/// (QotaEntity.categoryIcon, à ajouter côté modèle/SQL le jour où on
/// veut une icône différente par catégorie). Tant qu'il n'est pas
/// fourni ou ne correspond à rien, l'icône générique `category`
/// (assets/icons/category.svg) est utilisée.
class CategoryBadge extends StatelessWidget {
  final String label;
  final String? iconValue;

  const CategoryBadge({super.key, required this.label, this.iconValue});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: resolveEntityIcon(
          iconValue: iconValue ?? 'category',
          fallback: Icons.category_outlined,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
