import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/create_status_bar.dart';
import '../../data/feed_repository.dart';
import '../widgets/feed_item_card.dart';
import '../../../evaluer/presentation/screens/service_details_screen.dart';
import '../../../evaluer/presentation/screens/fullscreen_image_viewer.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../bon_plans/presentation/screens/bon_plans_screen.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/screens/add_user_item_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../profile/presentation/widgets/user_item_post_card.dart';

/// §9-12 : Home = logo Qota + loupe de recherche, puis le Feed
/// algorithmique (§10), paginé, mêlant Services et User Items.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = FeedRepository();
  final _profileRepository = ProfileRepository();
  final _scrollController = ScrollController();
  final List<FeedItem> _items = [];

  String? _avatarUrl;
  double? _userLat;
  double? _userLng;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _tryGetLocation();
    await _loadPage(reset: true);
    _loadAvatar();
  }

  /// Avatar utilisé uniquement pour l'affichage de la barre de statut —
  /// une erreur ici ne doit jamais bloquer le Feed.
  Future<void> _loadAvatar() async {
    try {
      final profile = await _profileRepository.getMyProfile();
      if (mounted) setState(() => _avatarUrl = profile.avatarUrl);
    } catch (_) {}
  }

  Future<void> _openAddUserItem() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddUserItemScreen()),
    );
    if (created == true) {
      _refresh();
    }
  }

  /// Nom/avatar d'une publication -> profil de son auteur. Si c'est
  /// l'utilisateur courant, on ouvre directement son Profil (éditable) ;
  /// sinon, la version publique en lecture seule.
  void _openOwnerProfile(String ownerId) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (ownerId == currentUserId) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: ownerId)),
      );
    }
  }

  /// La localisation est optionnelle pour l'algorithme (§10) — si
  /// l'utilisateur refuse, le Feed reste pertinent via fraîcheur/engagement.
  Future<void> _tryGetLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission granted = permission;
      if (permission == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.always ||
          granted == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        _userLat = position.latitude;
        _userLng = position.longitude;
      }
    } catch (_) {
      // Position indisponible -> l'algorithme applique un score de
      // proximité neutre, le Feed reste fonctionnel (§10).
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoadingMore || (!_hasMore && !reset)) {
      return;
    }

    setState(() => reset ? _isLoadingInitial = true : _isLoadingMore = true);

    final newItems = await _repository.getFeed(
      userLat: _userLat,
      userLng: _userLng,
      limit: _pageSize,
      offset: reset ? 0 : _items.length,
    );

    setState(() {
      if (reset) _items.clear();
      _items.addAll(newItems);
      _hasMore = newItems.length == _pageSize;
      _isLoadingInitial = false;
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    _hasMore = true;
    await _loadPage(reset: true);
  }

  /// Recharge le Feed EN SILENCE, sans jamais démonter la liste —
  /// contrairement à `_refresh()` (qui bascule sur un spinner plein
  /// écran, donc perd la position de scroll). Utilisée quand on
  /// revient d'une publication (détails, commentaires, image, note) :
  /// seules les données doivent se rafraîchir, jamais la position de
  /// lecture de l'utilisateur.
  Future<void> _refreshPreservingScroll() async {
    final newItems = await _repository.getFeed(
      userLat: _userLat,
      userLng: _userLng,
      limit: _pageSize,
      offset: 0,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(newItems);
      _hasMore = newItems.length == _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _QotaLogo(),
                Row(
                  children: [
                    _BonPlansButton(onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const BonPlansScreen()),
                      );
                    }),
                    const SizedBox(width: 12),
                    _SearchButton(onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: CreateStatusBar(
              avatarUrl: _avatarUrl,
              onTap: _openAddUserItem,
            ),
          ),
          Expanded(
            child: _isLoadingInitial
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(
                        child: Text('Rien à afficher pour le moment',
                            style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _items.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              );
                            }
                            final item = _items[index];

                            // User Item (§23) : même carte "publication"
                            // qu'au Profil (avatar/nom cliquables -> profil
                            // de l'auteur). Service (§18) : carte
                            // inchangée, jamais de propriétaire affiché.
                            if (item.kind == 'user_item') {
                              return UserItemPostCard(
                                itemId: item.id,
                                name: item.name,
                                description: item.description,
                                imageUrl: item.imageUrl,
                                ownerId: item.ownerId,
                                ownerName: item.ownerName ?? '',
                                ownerAvatarUrl: item.ownerAvatarUrl,
                                createdAt: item.createdAt,
                                averageScore: item.averageScore,
                                ratingsCount: item.ratingsCount,
                                commentsCount: item.commentsCount,
                                viewsCount: item.viewsCount,
                                onOpenProfile: item.ownerId != null
                                    ? () => _openOwnerProfile(item.ownerId!)
                                    : null,
                                onOpenRatingSheet: () => RatingSheet.show(
                                    context,
                                    entityId: item.id,
                                    onSubmitted: _refreshPreservingScroll),
                                onOpenComments: () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                      builder: (_) => CommentsScreen(
                                          entityId: item.id,
                                          entityKind: item.kind,
                                          entityOwnerId: item.ownerId),
                                    ))
                                    .then((_) => _refreshPreservingScroll()),
                                onOpenImageFullscreen: () => Navigator.of(
                                        context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => FullscreenImageViewer(
                                            imageUrl: item.imageUrl),
                                      ),
                                    )
                                    // Recharge pour refléter le nombre
                                    // de vues mis à jour côté base
                                    // (RPC increment_entity_views,
                                    // §023) — en silence, pour ne pas
                                    // perdre la position de scroll.
                                    .then((_) => _refreshPreservingScroll()),
                              );
                            }

                            return FeedItemCard(
                              item: item,
                              onOpenDetails: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                    builder: (_) =>
                                        ServiceDetailsScreen(entityId: item.id),
                                  ))
                                  .then((_) => _refreshPreservingScroll()),
                              onOpenRatingSheet: () => RatingSheet.show(context,
                                  entityId: item.id,
                                  onSubmitted: _refreshPreservingScroll),
                              onOpenComments: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                    builder: (_) => CommentsScreen(
                                        entityId: item.id,
                                        entityKind: item.kind),
                                  ))
                                  .then((_) => _refreshPreservingScroll()),
                              onOpenImageFullscreen: () => Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => FullscreenImageViewer(
                                          imageUrl: item.imageUrl),
                                    ),
                                  )
                                  .then((_) => _refreshPreservingScroll()),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _QotaLogo extends StatelessWidget {
  const _QotaLogo();

  @override
  Widget build(BuildContext context) {
    // Même dégradé que le "Q" du logo officiel (QotaBrandMark, écran
    // de connexion) — AppColors.brandOrangeGradient, pour une identité
    // visuelle cohérente entre le logo et le mot "Qota" de la Home.
    return ShaderMask(
      shaderCallback: (bounds) =>
          AppColors.brandOrangeGradient.createShader(bounds),
      child: const Text(
        'Qota',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: Colors.white, // requis par ShaderMask (masqué par le dégradé)
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
            color: AppColors.surfaceChip, shape: BoxShape.circle),
        child: const Icon(Icons.search_rounded, color: AppColors.iconDefault),
      ),
    );
  }
}

class _BonPlansButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BonPlansButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
            color: AppColors.surfaceChip, shape: BoxShape.circle),
        child:
            const Icon(Icons.local_offer_rounded, color: AppColors.iconDefault),
      ),
    );
  }
}
