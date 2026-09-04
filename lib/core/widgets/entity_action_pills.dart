import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bouton "pilule" orange clair pour une action sur une publication
/// (Évaluer / Commenter / Vues) — même style partout dans l'app.
class ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ActionPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryOrange),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

/// Rangée des 3 actions standard d'une publication — Évaluer (⭐ note
/// + nb avis), Commenter (💬 nb commentaires), Vues (👁 nb vues, non
/// cliquable). Utilisé partout où une publication est affichée
/// (carte, détail, feed) pour un style cohérent (§25).
class EntityActionPills extends StatelessWidget {
  final double averageScore;
  final int ratingsCount;
  final int commentsCount;
  final int viewsCount;
  final VoidCallback onTapRate;
  final VoidCallback onTapComment;

  /// Optionnel : formatage compact des vues (ex: "1.2K"). Sans lui,
  /// le nombre brut est affiché.
  final String Function(int count)? formatViews;

  const EntityActionPills({
    super.key,
    required this.averageScore,
    required this.ratingsCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.onTapRate,
    required this.onTapComment,
    this.formatViews,
  });

  @override
  Widget build(BuildContext context) {
    final viewsLabel =
        formatViews != null ? formatViews!(viewsCount) : '$viewsCount';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionPill(
          icon: Icons.star_rounded,
          label: '${averageScore.toStringAsFixed(1)} ($ratingsCount)',
          onTap: onTapRate,
        ),
        ActionPill(
          icon: Icons.chat_bubble_outline_rounded,
          label: '$commentsCount',
          onTap: onTapComment,
        ),
        ActionPill(
          icon: Icons.visibility_outlined,
          label: viewsLabel,
        ),
      ],
    );
  }
}
