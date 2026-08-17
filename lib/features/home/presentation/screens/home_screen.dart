import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/feed_repository.dart';
import '../widgets/feed_item_card.dart';
import '../widgets/feed_user_item_card.dart';
import '../../../evaluer/presentation/screens/service_details_screen.dart';
import '../../../evaluer/presentation/screens/fullscreen_image_viewer.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';

/// §9-12 : Home = logo Qota + loupe de recherche, puis le Feed
/// algorithmique (§10), paginé, mêlant Services et User Items.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = FeedRepository();
  final _scrollController = ScrollController();
  final List<FeedItem> _items = [];

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
                _SearchButton(onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                }),
              ],
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

                            // §18 vs §23 : une Service ne montre jamais son
                            // propriétaire ; un User Item l'affiche toujours,
                            // avec nom/avatar cliquables vers son profil public.
                            if (item.kind == 'user_item') {
                              return FeedUserItemCard(
                                item: item,
                                onOpenRatingSheet: () => RatingSheet.show(
                                  context,
                                  entityId: item.id,
                                  onSubmitted: _refresh,
                                ),
                                onOpenComments: () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                      builder: (_) => CommentsScreen(
                                        entityId: item.id,
                                        entityKind: item.kind,
                                        entityOwnerId: item.ownerId,
                                      ),
                                    ))
                                    .then((_) => _refresh()),
                                onOpenImageFullscreen: () =>
                                    Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FullscreenImageViewer(
                                        imageUrl: item.imageUrl),
                                  ),
                                ),
                              );
                            }

                            return FeedItemCard(
                              item: item,
                              onOpenDetails: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                    builder: (_) =>
                                        ServiceDetailsScreen(entityId: item.id),
                                  ))
                                  .then((_) => _refresh()),
                              onOpenRatingSheet: () => RatingSheet.show(context,
                                  entityId: item.id, onSubmitted: _refresh),
                              onOpenComments: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                    builder: (_) => CommentsScreen(
                                        entityId: item.id,
                                        entityKind: item.kind),
                                  ))
                                  .then((_) => _refresh()),
                              onOpenImageFullscreen: () =>
                                  Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FullscreenImageViewer(
                                      imageUrl: item.imageUrl),
                                ),
                              ),
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
    return const Text(
      'Qota',
      style: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: AppColors.primaryOrange,
        letterSpacing: -0.5,
        shadows: [
          Shadow(offset: Offset(0.6, 0.6), color: Colors.black26),
        ],
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
