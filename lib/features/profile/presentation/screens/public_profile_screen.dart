import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/profile_models.dart';
import '../../data/profile_repository.dart';
import '../widgets/user_item_post_card.dart';
import '../../../evaluer/presentation/screens/fullscreen_image_viewer.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';

/// §7 : profil PUBLIC d'un autre utilisateur — photo, nom, User Items
/// publiés. Contrairement à ProfileScreen (soi-même), pas de wallet,
/// pas d'édition du nom, pas de composer "Qu'allons-nous évaluer ?".
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
    final profile = await _repository.getProfileById(widget.userId);
    final items = await _repository.getUserItems(widget.userId);
    return _PublicProfileData(profile: profile, items: items);
  }

  void _reload() {
    setState(() => _futureData = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: FutureBuilder<_PublicProfileData>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final profile = data.profile;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.surfaceChip,
                          backgroundImage: profile.avatarUrl != null
                              ? CachedNetworkImageProvider(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null
                              ? const Icon(Icons.person,
                                  size: 44, color: AppColors.iconInactive)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
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
                          item: item,
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
                                  entityOwnerId: profile.id,
                                ),
                              ))
                              .then((_) => _reload()),
                          onOpenImageFullscreen: () =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageViewer(
                                  imageUrl: item.imageUrl),
                            ),
                          ),
                        );
                      },
                      childCount: data.items.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PublicProfileData {
  final QotaProfile profile;
  final List<QotaUserItem> items;

  _PublicProfileData({required this.profile, required this.items});
}
