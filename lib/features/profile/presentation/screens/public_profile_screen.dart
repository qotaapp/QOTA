import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/profile_models.dart';
import '../../data/profile_repository.dart';
import '../widgets/bordered_info_card.dart';
import '../widgets/user_item_post_card.dart';
import '../../../evaluer/presentation/screens/fullscreen_image_viewer.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';

/// Profil PUBLIC d'un autre utilisateur — accessible en tapant sur son
/// nom/avatar depuis une publication (Home ou Profil). Lecture seule :
/// pas de solde, pas d'édition de nom, pas d'upload de photo — juste
/// son identité publique et ses User Items, comme sur son propre Profil.
class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _repository = ProfileRepository();
  late Future<_PublicProfileData> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _load();
  }

  Future<_PublicProfileData> _load() async {
    final profile = await _repository.getPublicProfile(widget.userId);
    final items = await _repository.getUserItems(widget.userId);
    return _PublicProfileData(profile: profile, items: items);
  }

  void _reload() {
    setState(() => _futureData = _load());
  }

  /// "mon Qota" : moyenne des évaluations reçues sur l'ensemble des
  /// User Items du profil — même calcul que sur le Profil personnel.
  double? _averageAcrossItems(List<QotaUserItem> items) {
    final rated = items.where((i) => i.ratingsCount > 0).toList();
    if (rated.isEmpty) {
      return null;
    }
    final sum = rated.fold<double>(0, (acc, i) => acc + i.averageScore);
    return sum / rated.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Profil'),
      ),
      body: FutureBuilder<_PublicProfileData>(
        future: _futureData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Impossible de charger ce profil.'),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final profile = data.profile;
          final averageScore = _averageAcrossItems(data.items);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        BorderedInfoCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundColor: AppColors.surfaceChip,
                                backgroundImage: profile.avatarUrl != null
                                    ? CachedNetworkImageProvider(
                                        profile.avatarUrl!)
                                    : null,
                                child: profile.avatarUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 34,
                                        color: AppColors.iconInactive,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  profile.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ---- Carte "mon Qota" — aussi visible des
                        // visiteurs, pas seulement du propriétaire.
                        BorderedInfoCard(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 40,
                                color: AppColors.starFilled,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    averageScore == null
                                        ? '—'
                                        : averageScore.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.starFilled,
                                    ),
                                  ),
                                  const Text(
                                    'mon Qota',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (data.items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Aucun User Item publié pour le moment',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = data.items[index];
                        return UserItemPostCard(
                          itemId: item.id,
                          name: item.name,
                          description: item.description,
                          imageUrl: item.imageUrl,
                          ownerId: item.ownerId,
                          ownerName: item.ownerName,
                          ownerAvatarUrl: item.ownerAvatarUrl,
                          createdAt: item.createdAt,
                          averageScore: item.averageScore,
                          ratingsCount: item.ratingsCount,
                          commentsCount: item.commentsCount,
                          viewsCount: item.viewsCount,
                          onOpenRatingSheet: () => RatingSheet.show(
                            context,
                            entityId: item.id,
                            onSubmitted: _reload,
                          ),
                          onOpenComments: () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                builder: (_) => CommentsScreen(
                                  entityId: item.id,
                                  entityKind: 'user_item',
                                  entityOwnerId: profile.id, // §34
                                ),
                              ))
                              .then((_) => _reload()),
                          onOpenImageFullscreen: () =>
                              Navigator.of(context)
                                  .push(
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageViewer(
                                  imageUrl: item.imageUrl),
                            ),
                          )
                                  .then((_) => _reload()),
                        );
                      },
                      childCount: data.items.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PublicProfileData {
  final PublicProfile profile;
  final List<QotaUserItem> items;

  _PublicProfileData({required this.profile, required this.items});
}
