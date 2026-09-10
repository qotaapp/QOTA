import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rating_models.dart';

/// §27-30 : système de Rating générique, unique pour toute entité.
class RatingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// §29 : si l'utilisateur a déjà évalué, la Rating Sheet doit
  /// pré-remplir sa note et son commentaire pour modification.
  Future<QotaRating?> getMyRating(String entityId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final rows = await _client
        .from('ratings')
        .select()
        .eq('entity_id', entityId)
        .eq('user_id', userId)
        .limit(1);

    if ((rows as List).isEmpty) {
      return null;
    }
    return QotaRating.fromMap(rows.first);
  }

  /// §28 : UNIQUE(user_id, entity_id) — un upsert met à jour l'évaluation
  /// existante au lieu d'en créer une deuxième.
  ///
  /// Si un avis (texte) est écrit, il est aussi publié dans les
  /// commentaires de l'entité — visible dans CommentsScreen, compté
  /// dans comments_count. `ratings.comment_id` retient ce lien : si
  /// l'utilisateur modifie sa note/son avis plus tard, le MÊME
  /// commentaire est mis à jour plutôt qu'un nouveau republié.
  Future<void> submitRating({
    required String entityId,
    required int score,
    String? commentText,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final existing = await getMyRating(entityId);

    String? commentId = existing?.commentId;
    final text = commentText?.trim();

    if (text != null && text.isNotEmpty) {
      if (commentId != null) {
        await _client.from('comments').update({
          'text': text,
          'image_url': imageUrl,
        }).eq('id', commentId);
      } else {
        final inserted = await _client
            .from('comments')
            .insert({
              'entity_id': entityId,
              'user_id': userId,
              'text': text,
              'image_url': imageUrl,
            })
            .select('id')
            .single();
        commentId = inserted['id'] as String;
      }
    }

    await _client.from('ratings').upsert(
      {
        'entity_id': entityId,
        'user_id': userId,
        'score': score,
        'comment_text': commentText,
        'image_url': imageUrl,
        'comment_id': commentId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,entity_id',
    );
  }

  /// §30 : image optionnelle, une seule, propre au Rating (jamais
  /// affichée dans la carte principale du Feed).
  Future<String> uploadRatingImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path =
        '$userId/ratings/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from('user-content').uploadBinary(path, bytes);
    return _client.storage.from('user-content').getPublicUrl(path);
  }
}
