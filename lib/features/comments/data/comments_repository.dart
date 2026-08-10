import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'comment_models.dart';

class CommentsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<QotaComment>> getComments(String entityId) async {
    final rows = await _client
        .from('comments_with_likes')
        .select()
        .eq('entity_id', entityId);
    return (rows as List).map((r) => QotaComment.fromMap(r)).toList();
  }

  Future<List<QotaCommentReply>> getReplies(String commentId) async {
    final rows = await _client
        .from('replies_with_likes')
        .select()
        .eq('comment_id', commentId);
    return (rows as List).map((r) => QotaCommentReply.fromMap(r)).toList();
  }

  /// §31 : image optionnelle, autorisée uniquement sur le commentaire principal.
  Future<String> uploadCommentImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final userId = currentUserId!;
    final path = '$userId/comments/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from('user-content').uploadBinary(path, bytes);
    return _client.storage.from('user-content').getPublicUrl(path);
  }

  Future<void> addComment({
    required String entityId,
    required String text,
    String? imageUrl,
  }) async {
    await _client.from('comments').insert({
      'entity_id': entityId,
      'user_id': currentUserId,
      'text': text,
      'image_url': imageUrl,
    });
  }

  /// §33 : une réponse ne contient jamais d'image.
  Future<void> addReply({
    required String commentId,
    required String text,
  }) async {
    await _client.from('comment_replies').insert({
      'comment_id': commentId,
      'user_id': currentUserId,
      'text': text,
    });
  }

  /// §32 : toggle — un like ou aucun, jamais plusieurs du même utilisateur.
  Future<void> toggleCommentLike(String commentId, bool currentlyLiked) async {
    final userId = currentUserId!;
    if (currentlyLiked) {
      await _client.from('comment_likes').delete().match({'comment_id': commentId, 'user_id': userId});
    } else {
      await _client.from('comment_likes').insert({'comment_id': commentId, 'user_id': userId});
    }
  }

  Future<void> toggleReplyLike(String replyId, bool currentlyLiked) async {
    final userId = currentUserId!;
    if (currentlyLiked) {
      await _client.from('reply_likes').delete().match({'reply_id': replyId, 'user_id': userId});
    } else {
      await _client.from('reply_likes').insert({'reply_id': replyId, 'user_id': userId});
    }
  }

  /// §34 : la règle (auteur / propriétaire de User Item / modération)
  /// est appliquée côté serveur via la fonction RPC `delete_comment`.
  Future<void> deleteComment(String commentId) async {
    await _client.rpc('delete_comment', params: {'p_comment_id': commentId});
  }
}
