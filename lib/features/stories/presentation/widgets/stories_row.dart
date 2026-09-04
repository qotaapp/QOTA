import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/stories_repository.dart';
import '../screens/add_story_screen.dart';
import '../screens/story_viewer_screen.dart';

/// Rangée de bulles Stories, affichée sous la barre "Qu'allons-nous
/// évaluer ?" (comme Facebook/Instagram) : la première bulle permet
/// d'en publier une, les suivantes ouvrent la visionneuse plein écran
/// pour un utilisateur donné.
class StoriesRow extends StatefulWidget {
  final String? myAvatarUrl;

  const StoriesRow({super.key, this.myAvatarUrl});

  @override
  State<StoriesRow> createState() => StoriesRowState();
}

class StoriesRowState extends State<StoriesRow> {
  final _repository = StoriesRepository();
  late Future<List<UserStories>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getActiveStoriesGroupedByUser();
  }

  /// Exposé pour que HomeScreen puisse rafraîchir la rangée après
  /// publication d'une nouvelle story, sans reconstruire tout l'écran.
  void reload() =>
      setState(() => _future = _repository.getActiveStoriesGroupedByUser());

  Future<void> _openAdd() async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddStoryScreen()),
    );
    if (published == true) reload();
  }

  void _openViewer(List<UserStories> groups, int startIndex) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) =>
              StoryViewerScreen(groups: groups, initialIndex: startIndex),
        ))
        .then((_) => reload());
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = Supabase.instance.client.auth.currentUser?.id;

    return SizedBox(
      height: 92,
      child: FutureBuilder<List<UserStories>>(
        future: _future,
        builder: (context, snapshot) {
          final groups = snapshot.data ?? [];
          // On retire mon propre groupe de la liste "autres" — sa
          // bulle est fusionnée avec le bouton "+" ci-dessous.
          final others = groups.where((g) => g.userId != myUserId).toList();
          final myGroup = groups
              .cast<UserStories?>()
              .firstWhere((g) => g?.userId == myUserId, orElse: () => null);

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _StoryBubble(
                label: 'Votre story',
                avatarUrl: myGroup?.userAvatarUrl ?? widget.myAvatarUrl,
                hasActiveStory: myGroup != null,
                showAddBadge: true,
                onTap: myGroup != null
                    ? () => _openViewer(groups, groups.indexOf(myGroup))
                    : _openAdd,
                onLongPress: myGroup != null ? _openAdd : null,
              ),
              ...others.map((group) => _StoryBubble(
                    label: group.userName,
                    avatarUrl: group.userAvatarUrl,
                    hasActiveStory: true,
                    onTap: () => _openViewer(groups, groups.indexOf(group)),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  final String label;
  final String? avatarUrl;
  final bool hasActiveStory;
  final bool showAddBadge;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _StoryBubble({
    required this.label,
    required this.avatarUrl,
    required this.hasActiveStory,
    required this.onTap,
    this.showAddBadge = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasActiveStory
                        ? const LinearGradient(
                            colors: [
                              AppColors.primaryOrange,
                              Color(0xFFFFC371)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasActiveStory
                        ? null
                        : Border.all(color: AppColors.divider, width: 1.5),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl!)
                        : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person,
                            color: AppColors.iconInactive)
                        : null,
                  ),
                ),
                if (showAddBadge)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child:
                          const Icon(Icons.add, size: 13, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
