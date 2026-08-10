import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/evaluer_models.dart';

/// §25 : [Image] / Nom / Localisation / ⭐ moyenne  nb_évaluations  💬 nb_commentaires
/// IMPORTANT : jamais de ❤️ sur cette carte (§25).
///
/// §26 : tap ⭐ -> Rating Sheet · tap 💬 -> commentaires ·
/// tap image -> plein écran · tap carte -> Service Details.
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
            GestureDetector(
              onTap: onOpenImageFullscreen,
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: entity.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceChip),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceChip,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entity.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  if (entity.locationLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entity.locationLabel,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: onOpenRatingSheet,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 18, color: AppColors.starFilled),
                              const SizedBox(width: 4),
                              Text(entity.averageScore.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Text('${entity.ratingsCount}',
                                  style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      InkWell(
                        onTap: onOpenComments,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded,
                                  size: 16, color: AppColors.iconDefault),
                              const SizedBox(width: 4),
                              Text('${entity.commentsCount}',
                                  style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      // Pas de ❤️ ici — supprimé de la carte principale par règle §25.
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
