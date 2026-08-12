import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/comment_models.dart';
import '../../data/comments_repository.dart';
import '../widgets/comment_tile.dart';

class CommentsScreen extends StatefulWidget {
  final String entityId;
  final String entityKind; // 'service' | 'user_item' | 'public_figure'
  final String?
      entityOwnerId; // pour appliquer §34 côté UI (le serveur re-vérifie de toute façon)

  const CommentsScreen({
    super.key,
    required this.entityId,
    required this.entityKind,
    this.entityOwnerId,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _repository = CommentsRepository();
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _pickedImage;
  bool _isPosting = false;
  late Future<List<QotaComment>> _futureComments;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _futureComments = _repository.getComments(widget.entityId);
  }

  void _reload() {
    setState(() => _futureComments = _repository.getComments(widget.entityId));
  }

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _postComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        final Uint8List bytes = await _pickedImage!.readAsBytes();
        final extension = _pickedImage!.name.split('.').last;
        imageUrl = await _repository.uploadCommentImage(
            bytes: bytes, fileExtension: extension);
      }
      await _repository.addComment(
          entityId: widget.entityId, text: text, imageUrl: imageUrl);
      _textController.clear();
      setState(() => _pickedImage = null);
      _reload();
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  /// §34 : le propriétaire d'un User Item peut supprimer n'importe quel
  /// commentaire dessus ; le propriétaire d'une Service ne le peut pas.
  /// L'auteur peut toujours supprimer le sien. Le serveur revalide tout.
  bool _canDelete(QotaComment comment) {
    final me = _currentUserId;
    if (me == null) return false;
    if (comment.userId == me) return true;
    if (widget.entityKind == 'user_item' && widget.entityOwnerId == me)
      return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commentaires')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<QotaComment>>(
              future: _futureComments,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('Aucun commentaire pour le moment',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentTile(
                      comment: comment,
                      onToggleLike: () async {
                        await _repository.toggleCommentLike(
                            comment.id, comment.likedByMe);
                        _reload();
                      },
                      onReply: (text) async {
                        await _repository.addReply(
                            commentId: comment.id, text: text);
                      },
                      onDelete: _canDelete(comment)
                          ? () async {
                              await _repository.deleteComment(comment.id);
                              _reload();
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_pickedImage != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(_pickedImage!.path),
                                width: 56, height: 56, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, size: 18),
                              onPressed: () =>
                                  setState(() => _pickedImage = null),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image_outlined,
                            color: AppColors.iconInactive),
                        onPressed: _pickImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _isPosting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded,
                                color: AppColors.primaryOrange),
                        onPressed: _isPosting ? null : _postComment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
