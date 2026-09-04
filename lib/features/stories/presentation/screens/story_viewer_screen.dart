import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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

  const StoryViewerScreen(
      {super.key, required this.groups, required this.initialIndex});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _groupIndex;
  int _storyIndex = 0;
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
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _progressController?.dispose();
    super.dispose();
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
                        backgroundImage: _currentGroup.userAvatarUrl != null
                            ? NetworkImage(_currentGroup.userAvatarUrl!)
                            : null,
                        child: _currentGroup.userAvatarUrl == null
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
}
