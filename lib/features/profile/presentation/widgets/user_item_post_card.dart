import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_network_image.dart';
import '../../../../core/widgets/entity_action_pills.dart';
import '../../data/profile_repository.dart';

/// Présentation façon "publication" : avatar + nom + date en tête,
/// texte libre, image, puis la barre de stats (⭐ moyenne, 💬 commentaires).
/// Le propriétaire est toujours affiché (§23). Utilisé À L'IDENTIQUE sur
/// le Profil ET la Home (même widget, mêmes champs) pour garantir un
/// rendu strictement identique aux deux endroits.
///
/// Paramètres pris à plat (plutôt qu'un `QotaUserItem`) pour pouvoir
/// être alimenté aussi bien par le Profil que par le Feed de la Home,
/// qui utilisent deux modèles Dart différents.
class UserItemPostCard extends StatelessWidget {
  final String itemId;
  final String name;
  final String? description;
  final String imageUrl;
  final String? ownerId;
  final String ownerName;
  final String? ownerAvatarUrl;
  final DateTime createdAt;
  final double averageScore;
  final int ratingsCount;
  final int commentsCount;
  final int viewsCount;

  final VoidCallback onOpenRatingSheet;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenImageFullscreen;

  /// Optionnel : si fourni, l'avatar ET le nom du propriétaire
  /// deviennent cliquables et mènent à son profil (public ou le
  /// sien). Laissé `null` quand la carte est déjà affichée SUR le
  /// profil de son propriétaire (Profil perso) — pas besoin d'y
  /// naviguer depuis là.
  final VoidCallback? onOpenProfile;

  /// Optionnel : si fourni, affiche un menu ⋮ dans l'en-tête proposant
  /// la suppression de la publication. Fourni UNIQUEMENT quand la carte
  /// affiche une publication de l'utilisateur courant (son propre
  /// Profil) — jamais sur le profil public d'un tiers.
  final VoidCallback? onDelete;

  const UserItemPostCard({
    super.key,
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.ownerName,
    required this.createdAt,
    required this.averageScore,
    required this.ratingsCount,
    required this.commentsCount,
    required this.onOpenRatingSheet,
    required this.onOpenComments,
    required this.onOpenImageFullscreen,
    this.viewsCount = 0,
    this.description,
    this.ownerId,
    this.ownerAvatarUrl,
    this.onOpenProfile,
    this.onDelete,
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
    final avatar = CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surfaceChip,
      backgroundImage: ownerAvatarUrl != null
          ? CachedNetworkImageProvider(ownerAvatarUrl!)
          : null,
      child: ownerAvatarUrl == null
          ? const Icon(Icons.person, color: AppColors.iconInactive)
          : null,
    );

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
                onOpenProfile != null
                    ? GestureDetector(onTap: onOpenProfile, child: avatar)
                    : avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onOpenProfile,
                        child: Text(
                          ownerName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.iconInactive),
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (_) => onDelete!(),
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
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description!),
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
              ProfileRepository().incrementViews(itemId);
              onOpenImageFullscreen();
            },
            child: AdaptiveNetworkImage(imageUrl: imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: EntityActionPills(
              averageScore: averageScore,
              ratingsCount: ratingsCount,
              commentsCount: commentsCount,
              viewsCount: viewsCount,
              onTapRate: onOpenRatingSheet,
              onTapComment: onOpenComments,
              formatViews: _formatViews,
            ),
          ),
        ],
      ),
    );
  }
}
