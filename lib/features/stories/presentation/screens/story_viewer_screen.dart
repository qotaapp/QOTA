import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/stories_repository.dart';

const _kImageDisplaySeconds = 5;

/// Visionneuse plein écran, façon Facebook/Instagram : barres de
/// progression en haut, avance automatique story par story puis
/// utilisateur par utilisateur, tap gauche/droite pour naviguer
/// manuellement.
class StoryViewerScreen extends StatefulWidget {
  final List<UserStories> groups;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.groups,
    required this.initialIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _groupIndex;
  int _storyIndex = 0;
  VideoPlayerController? _videoController;
  AnimationController? _progressController;

  UserStories get _currentGroup => widget.groups[_groupIndex];
  Story get _currentStory => _currentGroup.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialIndex;
    _loadCurrentStory();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _progressController?.dispose();
    super.dispose();
  }

  Future<void> _addReaction(String reactionType) async {
    final repository = StoriesRepository();
    try {
      await repository.addStoryReaction(
        storyId: _currentStory.id,
        reactionType: reactionType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réaction envoyée'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur réaction: $e');
    }
  }

  void _loadCurrentStory() {
    _progressController?.dispose();
    _videoController?.dispose();
    _videoController = null;

    if (_currentStory.mediaType == 'video') {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(_currentStory.mediaUrl));
      _videoController = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        controller.play();
        _startProgress(controller.value.duration);
      });
    } else {
      _startProgress(const Duration(seconds: _kImageDisplaySeconds));
    }
  }

  void _startProgress(Duration duration) {
    _progressController = AnimationController(vsync: this, duration: duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goNext();
      })
      ..forward();
    setState(() {});
  }

  void _goNext() {
    if (_storyIndex < _currentGroup.stories.length - 1) {
      setState(() => _storyIndex++);
      _loadCurrentStory();
    } else if (_groupIndex < widget.groups.length - 1) {
      setState(() {
        _groupIndex++;
        _storyIndex = 0;
      });
      _loadCurrentStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrevious() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _loadCurrentStory();
    } else if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _storyIndex = widget.groups[_groupIndex].stories.length - 1;
      });
      _loadCurrentStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMine = _currentGroup.userId == myUserId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _currentStory.mediaType == 'video' &&
                      _videoController != null &&
                      _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : _currentStory.mediaType == 'image'
                      ? Image.network(_currentStory.mediaUrl,
                          fit: BoxFit.contain)
                      : const CircularProgressIndicator(color: Colors.white),
            ),
            // Zones tap gauche/droite pour naviguer manuellement.
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _goPrevious,
                      behavior: HitTestBehavior.translucent,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _goNext,
                      behavior: HitTestBehavior.translucent,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Row(
                    children:
                        List.generate(_currentGroup.stories.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: index < _storyIndex
                              ? _filledBar()
                              : index == _storyIndex
                                  ? AnimatedBuilder(
                                      animation: _progressController ??
                                          const AlwaysStoppedAnimation(0),
                                      builder: (context, _) =>
                                          FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor:
                                            _progressController?.value ?? 0,
                                        child: _filledBar(),
                                      ),
                                    )
                                  : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        backgroundImage: (_currentGroup.userAvatarUrl != null &&
                                _currentGroup.userAvatarUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(
                                _currentGroup.userAvatarUrl!)
                            : null,
                        child: (_currentGroup.userAvatarUrl == null ||
                                _currentGroup.userAvatarUrl!.isEmpty)
                            ? const Icon(Icons.person,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isMine ? 'Vous' : _currentGroup.userName,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Boutons de réaction en bas
            if (!isMine)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ReactionButton(
                      icon: '❤️',
                      label: 'Love',
                      onTap: () => _addReaction('love'),
                    ),
                    const SizedBox(width: 24),
                    _ReactionButton(
                      icon: '🎁',
                      label: 'Gift',
                      onTap: () => _addReaction('gift'),
                    ),
                    const SizedBox(width: 24),
                    _ReactionButton(
                      icon: '👎',
                      label: 'Dislike',
                      onTap: () => _addReaction('dislike'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filledBar() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      );
} // ✅ FERMETURE de _StoryViewerScreenState

// ✅ _ReactionButton est maintenant TOP-LEVEL, plus imbriqué
class _ReactionButton extends StatefulWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.3).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        ),
        child: Column(
          children: [
            Text(widget.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
