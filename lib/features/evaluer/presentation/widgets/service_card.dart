import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_network_image.dart';
import '../../data/evaluer_models.dart';

/// §25 : [Image] / Nom / Localisation / ⭐ moyenne  nb_évaluations  💬 nb_commentaires  👁 nb_vues
/// IMPORTANT : jamais de ❤️ sur cette carte (§25).
///
/// §26 : tap ⭐ -> Rating Sheet · tap 💬 -> commentaires ·
/// tap image -> plein écran · tap carte -> Service Details.
///
/// Le badge "En attente d'approbation" ne s'affiche QUE pour le
/// créateur : entity_cards_view ne renvoie jamais la Service
/// pending_review d'un autre utilisateur (voir migration SQL dédiée),
/// donc `entity.isPendingReview == true` signifie forcément "c'est la
/// mienne" — aucune vérification d'identité supplémentaire requise ici.
class ServiceCard extends StatelessWidget {
  final QotaEntity entity;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenRatingSheet;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenImageFullscreen;

  const ServiceCard({
    super.key,
    required this.entity,
    required this.onOpenDetails,
    required this.onOpenRatingSheet,
    required this.onOpenComments,
    required this.onOpenImageFullscreen,
  });

  /// Format compact façon réseaux sociaux : 1200 -> "1.2K", 2500000 -> "2.5M".
  String _formatViews(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenDetails,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: onOpenImageFullscreen,
                  child: AdaptiveNetworkImage(imageUrl: entity.imageUrl),
                ),
                if (entity.isPendingReview)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_top_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'En attente d\'approbation',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entity.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  if (entity.locationLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entity.locationLabel,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: onOpenRatingSheet,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 18, color: AppColors.starFilled),
                              const SizedBox(width: 4),
                              Text(entity.averageScore.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Text('${entity.ratingsCount}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      InkWell(
                        onTap: onOpenComments,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded,
                                  size: 16, color: AppColors.iconDefault),
                              const SizedBox(width: 4),
                              Text('${entity.commentsCount}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      // Pas de ❤️ ici — supprimé de la carte principale par règle §25.
                      const Spacer(),
                      // Compteur de vues — bas droite, icône œil.
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: AppColors.iconInactive,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatViews(entity.viewsCount),
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
