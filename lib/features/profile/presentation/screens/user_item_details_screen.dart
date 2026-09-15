import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/entity_action_pills.dart';
import '../../data/profile_models.dart';
import '../../data/profile_repository.dart';
import '../../../evaluer/presentation/screens/fullscreen_image_viewer.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';

/// Fiche d'un User Item, affichée en dialog centré — même patron que
/// ServiceDetailsScreen. Le propriétaire est TOUJOURS affiché (§23),
/// contrairement à la fiche Service.
class UserItemDetailsScreen extends StatefulWidget {
  final String itemId;

  /// Optionnel : si fourni, taper sur l'avatar/le nom du propriétaire
  /// ferme le dialog puis navigue vers son profil.
  final VoidCallback? onOpenProfile;

  const UserItemDetailsScreen({
    super.key,
    required this.itemId,
    this.onOpenProfile,
  });

  static Future<void> show(
    BuildContext context, {
    required String itemId,
    VoidCallback? onDismiss,
    VoidCallback? onOpenProfile,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
          child: UserItemDetailsScreen(
            itemId: itemId,
            onOpenProfile: onOpenProfile,
          ),
        ),
      ),
    );
    onDismiss?.call();
  }

  @override
  State<UserItemDetailsScreen> createState() => _UserItemDetailsScreenState();
}

class _UserItemDetailsScreenState extends State<UserItemDetailsScreen> {
  final _repository = ProfileRepository();
  late Future<QotaUserItem?> _futureItem;

  @override
  void initState() {
    super.initState();
    _futureItem = _repository.getUserItemById(widget.itemId);
  }

  void _reload() {
    setState(() => _futureItem = _repository.getUserItemById(widget.itemId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QotaUserItem?>(
      future: _futureItem,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = snapshot.data;
        if (item == null) {
          return const SizedBox(
            height: 140,
            child: Center(child: Text('Publication introuvable')),
          );
        }

        return Stack(
          children: [
            SingleChildScrollView(
              //shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // §23 : propriétaire toujours affiché, cliquable si
                  // onOpenProfile fourni.
                  InkWell(
                    onTap: widget.onOpenProfile == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onOpenProfile!.call();
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
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
                        Text(item.ownerName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FullscreenImageViewer(imageUrl: item.imageUrl),
                        ),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: CachedNetworkImage(
                            imageUrl: item.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),

                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(item.description!),
                  ],
                  const SizedBox(height: 16),

                  EntityActionPills(
                    averageScore: item.averageScore,
                    ratingsCount: item.ratingsCount,
                    commentsCount: item.commentsCount,
                    viewsCount: item.viewsCount,
                    onTapRate: () => RatingSheet.show(context,
                        entityId: item.id, onSubmitted: _reload),
                    onTapComment: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                          builder: (_) => CommentsScreen(
                            entityId: item.id,
                            entityKind: 'user_item',
                            entityOwnerId: item.ownerId, // §34
                          ),
                        ))
                        .then((_) => _reload()),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange),
                          onPressed: () => RatingSheet.show(context,
                              entityId: item.id, onSubmitted: _reload),
                          icon: const Icon(Icons.star_rounded),
                          label: const Text('Évaluer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                builder: (_) => CommentsScreen(
                                  entityId: item.id,
                                  entityKind: 'user_item',
                                  entityOwnerId: item.ownerId,
                                ),
                              ))
                              .then((_) => _reload()),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Commenter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }
}
