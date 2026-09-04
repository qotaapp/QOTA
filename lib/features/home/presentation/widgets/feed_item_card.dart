import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_network_image.dart';
import '../../../../core/widgets/entity_action_pills.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/feed_repository.dart';

/// §9/§25 : carte pour les Services affichées dans le Feed (jamais de
/// propriétaire, §18). Les User Items utilisent UserItemPostCard.
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
            GestureDetector(
              onTap: () {
                ProfileRepository().incrementViews(item.id);
                onOpenImageFullscreen();
              },
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
                  EntityActionPills(
                    averageScore: item.averageScore,
                    ratingsCount: item.ratingsCount,
                    commentsCount: item.commentsCount,
                    viewsCount: item.viewsCount,
                    onTapRate: onOpenRatingSheet,
                    onTapComment: onOpenComments,
                    formatViews: _formatViews,
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
