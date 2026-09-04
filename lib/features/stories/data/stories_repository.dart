import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class Story {
  final String id;
  final String userId;
  final String mediaUrl;
  final String mediaType; // 'image' | 'video'
  final DateTime createdAt;

  Story({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
  });

  factory Story.fromMap(Map<String, dynamic> map) => Story(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        mediaUrl: map['media_url'] as String,
        mediaType: map['media_type'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// Regroupe les stories actives (< 24h) d'un même utilisateur, pour
/// afficher une seule bulle par personne dans la rangée (comme
/// Facebook/Instagram) — même si elle a publié plusieurs stories.
class UserStories {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final List<Story> stories;

  UserStories({
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.stories,
  });
}

/// Répertoire Stories : contenu éphémère (photo/vidéo ≤ 40s),
/// masqué après 24h uniquement via le filtre `created_at` de la
/// requête — jamais supprimé de la base (choix explicite : pas de
/// tâche planifiée nécessaire).
class StoriesRepository {
  final SupabaseClient _client = Supabase.instance.client;

  DateTime get _cutoff =>
      DateTime.now().toUtc().subtract(const Duration(hours: 24));

  /// Stories actives de tout le monde, groupées par auteur — la plus
  /// récente publication de chacun détermine l'ordre de la rangée.
  Future<List<UserStories>> getActiveStoriesGroupedByUser() async {
    final rows = await _client
        .from('stories')
        .select('id, user_id, media_url, media_type, created_at, '
            'profiles(first_name, last_name, avatar_url)')
        .gte('created_at', _cutoff.toIso8601String())
        .order('created_at');

    final grouped = <String, UserStories>{};
    for (final r in rows as List) {
      final userId = r['user_id'] as String;
      final story = Story.fromMap(r);
      final profile = r['profiles'] as Map<String, dynamic>?;

      final existing = grouped[userId];
      if (existing == null) {
        grouped[userId] = UserStories(
          userId: userId,
          userName: profile != null
              ? '${profile['first_name']} ${profile['last_name']}'
              : '',
          userAvatarUrl: profile?['avatar_url'] as String?,
          stories: [story],
        );
      } else {
        existing.stories.add(story);
      }
    }

    // Les groupes les plus récemment mis à jour en premier.
    final result = grouped.values.toList()
      ..sort((a, b) =>
          b.stories.last.createdAt.compareTo(a.stories.last.createdAt));
    return result;
  }

  Future<List<Story>> getMyActiveStories() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('stories')
        .select()
        .eq('user_id', userId)
        .gte('created_at', _cutoff.toIso8601String())
        .order('created_at');
    return (rows as List).map((r) => Story.fromMap(r)).toList();
  }

  Future<String> uploadStoryMedia(
      {required Uint8List bytes, required String fileExtension}) async {
    final userId = _client.auth.currentUser!.id;
    final path =
        '$userId/stories/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from('user-content').uploadBinary(path, bytes);
    return _client.storage.from('user-content').getPublicUrl(path);
  }

  Future<void> createStory({
    required String mediaUrl,
    required String mediaType,
    int? durationSeconds,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('stories').insert({
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'duration_seconds': durationSeconds,
    });
  }
}
