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
    if (userId == null) return null;

    final rows = await _client
        .from('ratings')
        .select()
        .eq('entity_id', entityId)
        .eq('user_id', userId)
        .limit(1);

    if ((rows as List).isEmpty) return null;
    return QotaRating.fromMap(rows.first);
  }

  /// §28 : UNIQUE(user_id, entity_id) — un upsert met à jour l'évaluation
  /// existante au lieu d'en créer une deuxième.
  Future<void> submitRating({
    required String entityId,
    required int score,
    String? commentText,
    String? imageUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('ratings').upsert(
      {
        'entity_id': entityId,
        'user_id': userId,
        'score': score,
        'comment_text': commentText,
        'image_url': imageUrl,
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
    final path = '$userId/ratings/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from('user-content').uploadBinary(path, bytes);
    return _client.storage.from('user-content').getPublicUrl(path);
  }
}
