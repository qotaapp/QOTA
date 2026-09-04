import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/stories_repository.dart';

const _kMaxStoryDurationSeconds = 40;

/// Ajout d'une story (photo ou vidéo, vidéo limitée à 40s) — accessible
/// depuis la bulle "+" de la rangée Stories, sous la barre "Qu'allons-
/// nous évaluer ?".
class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  final _repository = StoriesRepository();
  final _picker = ImagePicker();

  XFile? _pickedFile;
  String? _mediaType; // 'image' | 'video'
  VideoPlayerController? _videoController;
  int? _videoDurationSeconds;

  bool _isPublishing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    _videoController?.dispose();
    setState(() {
      _pickedFile = file;
      _mediaType = 'image';
      _videoController = null;
      _videoDurationSeconds = null;
      _errorMessage = null;
    });
  }

  Future<void> _pickVideo(ImageSource source) async {
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: _kMaxStoryDurationSeconds),
    );
    if (file == null) return;

    // maxDuration ne limite que l'enregistrement caméra — une vidéo
    // choisie depuis la galerie peut être plus longue, on vérifie
    // donc systématiquement la durée réelle avant de l'accepter.
    final controller = VideoPlayerController.file(File(file.path));
    await controller.initialize();
    final durationSeconds = controller.value.duration.inSeconds;

    if (durationSeconds > _kMaxStoryDurationSeconds) {
      controller.dispose();
      setState(() {
        _errorMessage =
            'La vidéo dépasse $_kMaxStoryDurationSeconds secondes ($durationSeconds s). Choisissez un extrait plus court.';
      });
      return;
    }

    _videoController?.dispose();
    setState(() {
      _pickedFile = file;
      _mediaType = 'video';
      _videoController = controller
        ..setLooping(true)
        ..play();
      _videoDurationSeconds = durationSeconds;
      _errorMessage = null;
    });
  }

  Future<void> _showSourcePicker({required bool isVideo}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre avec la caméra'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (isVideo) {
      await _pickVideo(source);
    } else {
      await _pickImage(source);
    }
  }

  Future<void> _publish() async {
    if (_pickedFile == null || _mediaType == null) return;

    setState(() {
      _isPublishing = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _pickedFile!.readAsBytes();
      final extension = _pickedFile!.name.split('.').last;
      final mediaUrl = await _repository.uploadStoryMedia(
          bytes: bytes, fileExtension: extension);

      await _repository.createStory(
        mediaUrl: mediaUrl,
        mediaType: _mediaType!,
        durationSeconds: _videoDurationSeconds,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Publication impossible. Réessayez.';
        _isPublishing = false;
      });
    }
  }

  Widget _buildPreview() {
    if (_pickedFile == null) {
      return const Center(
        child: Text('Choisissez une photo ou une vidéo (40s max)',
            style: TextStyle(color: Colors.white70)),
      );
    }
    if (_mediaType == 'video' && _videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }
    return Image.file(File(_pickedFile!.path), fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Nouvelle story'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildPreview()),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38)),
                      onPressed: () => _showSourcePicker(isVideo: false),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38)),
                      onPressed: () => _showSourcePicker(isVideo: true),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Vidéo'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed:
                      (_pickedFile == null || _isPublishing) ? null : _publish,
                  child: _isPublishing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Publier ma story'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
