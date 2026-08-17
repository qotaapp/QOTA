import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/profile_models.dart';
import '../../data/profile_repository.dart';

/// Présentation façon "publication" : avatar + nom + date en tête,
/// texte libre, image, puis la barre de stats (⭐ moyenne, 💬 commentaires).
/// Le propriétaire est toujours affiché (§23) — logique déjà correcte,
/// seule la mise en page change ici.
class UserItemPostCard extends StatelessWidget {
  final QotaUserItem item;
  final VoidCallback onOpenRatingSheet;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenImageFullscreen;

  const UserItemPostCard({
    super.key,
    required this.item,
    required this.onOpenRatingSheet,
    required this.onOpenComments,
    required this.onOpenImageFullscreen,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours} h';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

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
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceChip,
                  child: Icon(Icons.person, color: AppColors.iconInactive),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.ownerName,
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
              // Une vue = ouverture délibérée de l'image, pas juste un
              // défilement dans la liste (évite de gonfler le compteur
              // artificiellement à chaque scroll).
              ProfileRepository().incrementViews(item.id);
              onOpenImageFullscreen();
            },
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                  imageUrl: item.imageUrl, fit: BoxFit.cover),
            ),
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
