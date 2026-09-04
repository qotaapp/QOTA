import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/entity_action_pills.dart';
import '../../data/profile_models.dart';

/// Même esprit visuel que ServiceCard (§25), mais le nom du
/// propriétaire est affiché — c'est la différence fondamentale
/// entre un User Item et une Service (§18 vs §23).
class UserItemCard extends StatelessWidget {
  final QotaUserItem item;
  final VoidCallback onOpenRatingSheet;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenImageFullscreen;

  const UserItemCard({
    super.key,
    required this.item,
    required this.onOpenRatingSheet,
    required this.onOpenComments,
    required this.onOpenImageFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  imageUrl: item.imageUrl, fit: BoxFit.cover),
            ),
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
                // §23 : propriétaire affiché publiquement.
                Text('Par ${item.ownerName}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                EntityActionPills(
                  averageScore: item.averageScore,
                  ratingsCount: item.ratingsCount,
                  commentsCount: item.commentsCount,
                  viewsCount: item.viewsCount,
                  onTapRate: onOpenRatingSheet,
                  onTapComment: onOpenComments,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
