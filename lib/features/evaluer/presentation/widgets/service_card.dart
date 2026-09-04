import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_network_image.dart';
import '../../../../core/widgets/entity_action_pills.dart';
import '../../../profile/data/profile_repository.dart';
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
              onTap: () {
                ProfileRepository().incrementViews(entity.id);
                onOpenImageFullscreen();
              },
              child: AdaptiveNetworkImage(imageUrl: entity.imageUrl),
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
                  EntityActionPills(
                    averageScore: entity.averageScore,
                    ratingsCount: entity.ratingsCount,
                    commentsCount: entity.commentsCount,
                    viewsCount: entity.viewsCount,
                    onTapRate: onOpenRatingSheet,
                    onTapComment: onOpenComments,
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
