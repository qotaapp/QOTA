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
  late Future<StoryReactionCounts> _reactionCountsFuture;
  VideoPlayerController? _videoController;
  AnimationController? _progressController;

  final _repository = StoriesRepository();

  UserStories get _currentGroup => widget.groups[_groupIndex];
  Story get _currentStory => _currentGroup.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialIndex;
    _loadCurrentStory();
    _reactionCountsFuture = _repository.getReactionCounts(_currentStory.id);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _progressController?.dispose();
    super.dispose();
  }

  Future<void> _addReaction(String reactionType) async {
    try {
      await _repository.addStoryReaction(
        storyId: _currentStory.id,
        reactionType: reactionType,
        amount: 1, // 1 coin pour gift
      );
      if (mounted) {
        setState(() {
          _reactionCountsFuture =
              _repository.getReactionCounts(_currentStory.id);
        });
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
    _progressController = null;
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
    if (mounted) setState(() {});
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

  Widget _filledBar() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      );

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
                      ? CachedNetworkImage(
                          imageUrl: _currentStory.mediaUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                          ),
                        )
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

            // Barres de progression + header
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
                child: FutureBuilder<StoryReactionCounts>(
                  future: _reactionCountsFuture,
                  builder: (context, snapshot) {
                    final counts = snapshot.data ??
                        StoryReactionCounts(
                          loveCount: 0,
                          giftCount: 0,
                          dislikeCount: 0,
                        );

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ReactionButton(
                          icon: '❤️',
                          label: 'Love',
                          count: counts.loveCount,
                          onTap: () => _addReaction('love'),
                        ),
                        const SizedBox(width: 24),
                        _ReactionButton(
                          icon: '🎁',
                          label: 'Donation',
                          count: counts.giftCount,
                          subtitle: 'coins',
                          onTap: () => _addReaction('gift'),
                        ),
                        const SizedBox(width: 24),
                        _ReactionButton(
                          icon: '👎',
                          label: 'Dislike',
                          count: counts.dislikeCount,
                          onTap: () => _addReaction('dislike'),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ✅ _ReactionButton TOP-LEVEL (hors de _StoryViewerScreenState)
class _ReactionButton extends StatefulWidget {
  final String icon;
  final String label;
  final int count;
  final String? subtitle; // 'coins' pour gift
  final VoidCallback onTap;

  const _ReactionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.subtitle,
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

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.3).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            if (widget.count > 0) ...[
              const SizedBox(height: 2),
              Text(
                widget.subtitle != null
                    ? '${widget.count} ${widget.subtitle}'
                    : '${widget.count}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
