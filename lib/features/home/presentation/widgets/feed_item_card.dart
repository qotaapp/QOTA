import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_network_image.dart';
import '../../data/feed_repository.dart';

/// §9/§25 : carte pour les Services affichées dans le Feed (jamais de
/// propriétaire, §18). Les User Items utilisent FeedUserItemCard.
class FeedItemCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenRatingSheet;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenImageFullscreen;

  const FeedItemCard({
    super.key,
    required this.item,
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
              child: AdaptiveNetworkImage(imageUrl: item.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    // §23 : propriétaire pour un User Item / localisation pour une Service.
                    item.kind == 'user_item'
                        ? 'Par ${item.ownerName ?? ''}'
                        : item.locationLabel,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: onOpenRatingSheet,
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 18, color: AppColors.starFilled),
                            const SizedBox(width: 4),
                            Text(item.averageScore.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            Text('${item.ratingsCount}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      InkWell(
                        onTap: onOpenComments,
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 16),
                            const SizedBox(width: 4),
                            Text('${item.commentsCount}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
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
