import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_network_image.dart';
import '../../data/feed_repository.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';

/// Même présentation que UserItemPostCard (Profil), mais pour les
/// User Items affichés dans le Feed Home : le nom/avatar sont
/// cliquables et ouvrent le profil PUBLIC du propriétaire (§7).
/// Réservée aux items kind='user_item' — les Services gardent
/// FeedItemCard (jamais de propriétaire affiché, §18).
class FeedUserItemCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onOpenRatingSheet;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenImageFullscreen;

  const FeedUserItemCard({
    super.key,
    required this.item,
    required this.onOpenRatingSheet,
    required this.onOpenComments,
    required this.onOpenImageFullscreen,
  });

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours} h';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatViews(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  void _openOwnerProfile(BuildContext context) {
    final ownerId = item.ownerId;
    if (ownerId == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: ownerId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: InkWell(
              onTap: () => _openOwnerProfile(context),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceChip,
                    backgroundImage: item.ownerAvatarUrl != null
                        ? CachedNetworkImageProvider(item.ownerAvatarUrl!)
                        : null,
                    child: item.ownerAvatarUrl == null
                        ? const Icon(Icons.person,
                            color: AppColors.iconInactive)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ownerName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _formatDate(item.createdAt),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.description!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              ProfileRepository().incrementViews(item.id);
              onOpenImageFullscreen();
            },
            child: AdaptiveNetworkImage(imageUrl: item.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                InkWell(
                  onTap: onOpenRatingSheet,
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 20, color: AppColors.starFilled),
                      const SizedBox(width: 4),
                      Text(
                        item.averageScore.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                InkWell(
                  onTap: onOpenComments,
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      const SizedBox(width: 4),
                      Text('${item.commentsCount}'),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.iconInactive,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatViews(item.viewsCount),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
