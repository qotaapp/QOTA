import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/rating_models.dart';
import '../../data/rating_repository.dart';

/// §29 : Bottom Sheet extrêmement simple et petite.
/// Contenu : Évaluer / ☆☆☆☆☆ / Commentaire (optionnel) / 📷 Ajouter une
/// photo / [Publier]. Le bouton Publier n'est actif qu'après le choix
/// d'une note. Si l'utilisateur a déjà évalué, sa note et son
/// commentaire sont pré-remplis pour modification.
class RatingSheet extends StatefulWidget {
  final String entityId;
  final VoidCallback? onSubmitted;

  const RatingSheet({super.key, required this.entityId, this.onSubmitted});

  static Future<void> show(BuildContext context,
      {required String entityId, VoidCallback? onSubmitted}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RatingSheet(entityId: entityId, onSubmitted: onSubmitted),
    );
  }

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  final _repository = RatingRepository();
  final _commentController = TextEditingController();
  final _picker = ImagePicker();

  int _selectedScore = 0;
  XFile? _pickedImage;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRating() async {
    final QotaRating? existing = await _repository.getMyRating(widget.entityId);
    if (existing != null) {
      _selectedScore = existing.score;
      _commentController.text = existing.commentText ?? '';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _handlePublish() async {
    if (_selectedScore == 0) return; // §29 : Publier inactif sans note

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        final Uint8List bytes = await _pickedImage!.readAsBytes();
        final extension = _pickedImage!.name.split('.').last;
        imageUrl = await _repository.uploadRatingImage(
            bytes: bytes, fileExtension: extension);
      }

      await _repository.submitRating(
        entityId: widget.entityId,
        score: _selectedScore,
        commentText: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        imageUrl: imageUrl,
      );

      widget.onSubmitted?.call();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 160, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Évaluer',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),

                // §29 : ☆ ☆ ☆ ☆ ☆
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    final filled = starValue <= _selectedScore;
                    return IconButton(
                      onPressed: () =>
                          setState(() => _selectedScore = starValue),
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.starFilled,
                        size: 34,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Votre avis...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(_pickedImage == null
                          ? 'Ajouter une photo'
                          : 'Photo sélectionnée'),
                    ),
                    if (_pickedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_pickedImage!.path),
                            width: 40, height: 40, fit: BoxFit.cover),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  // §29 : Publier disponible uniquement après le choix d'une note.
                  onPressed: (_selectedScore == 0 || _isSubmitting)
                      ? null
                      : _handlePublish,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Publier'),
                ),
              ],
            ),
    );
  }
}
