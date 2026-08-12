import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/comment_models.dart';
import '../../data/comments_repository.dart';
import 'reply_tile.dart';

/// §31 : nom de l'auteur / texte / image optionnelle / 👍 Like / ↩ Répondre.
/// AUCUNE étoile ici — le Rating est un système distinct (§27).
class CommentTile extends StatefulWidget {
  final QotaComment comment;
  final VoidCallback onToggleLike;
  final VoidCallback? onDelete; // null si l'utilisateur n'a pas le droit (§34)
  final void Function(String text) onReply;

  const CommentTile({
    super.key,
    required this.comment,
    required this.onToggleLike,
    required this.onReply,
    this.onDelete,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  final _repository = CommentsRepository();
  final _replyController = TextEditingController();
  bool _showReplyField = false;
  bool _showReplies = false;
  Future<List<QotaCommentReply>>? _repliesFuture;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _toggleReplies() {
    setState(() {
      _showReplies = !_showReplies;
      _repliesFuture ??= _repository.getReplies(widget.comment.id);
    });
  }

  void _submitReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    widget.onReply(text);
    _replyController.clear();
    setState(() {
      _showReplyField = false;
      _repliesFuture = _repository.getReplies(widget.comment.id); // recharge
      _showReplies = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(comment.text),
                  ],
                ),
              ),
              if (widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.iconInactive),
                  onPressed: widget.onDelete,
                ),
            ],
          ),
          if (comment.imageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: () {
                  // TODO : plein écran avec zoom (même comportement que §26)
                },
                child: CachedNetworkImage(
                  imageUrl: comment.imageUrl!,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                onTap: widget.onToggleLike,
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up_alt_rounded,
                      size: 16,
                      color: comment.likedByMe
                          ? AppColors.primaryOrange
                          : AppColors.iconInactive,
                    ),
                    const SizedBox(width: 4),
                    Text('${comment.likesCount}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              InkWell(
                onTap: () => setState(() => _showReplyField = !_showReplyField),
                child: const Text('↩ Répondre',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const Spacer(),
              TextButton(
                onPressed: _toggleReplies,
                child: Text(_showReplies
                    ? 'Masquer les réponses'
                    : 'Voir les réponses'),
              ),
            ],
          ),
          if (_showReplyField) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: 'Votre réponse...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: AppColors.primaryOrange),
                  onPressed: _submitReply,
                ),
              ],
            ),
          ],
          if (_showReplies)
            FutureBuilder<List<QotaCommentReply>>(
              future: _repliesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(left: 40, top: 8),
                    child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final replies = snapshot.data ?? [];
                return Column(
                  children: replies
                      .map((r) => ReplyTile(
                            reply: r,
                            onToggleLike: () async {
                              await _repository.toggleReplyLike(
                                  r.id, r.likedByMe);
                              setState(() => _repliesFuture =
                                  _repository.getReplies(widget.comment.id));
                            },
                          ))
                      .toList(),
                );
              },
            ),
          const Divider(height: 22),
        ],
      ),
    );
  }
}
