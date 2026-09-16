import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Compte des réactions pour une story
class StoryReactionCounts {
  final int loveCount;
  final int giftCount;
  final int dislikeCount;

  StoryReactionCounts({
    required this.loveCount,
    required this.giftCount,
    required this.dislikeCount,
  });
}

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
  /// Passe par `stories_view` (035) et non par un embed `profiles(...)`
  /// sur `stories` : un embed PostgREST respecte les RLS de `profiles`
  /// (lecture limitée à soi-même), ce qui masquait avatar/nom des
  /// autres utilisateurs.
  Future<List<UserStories>> getActiveStoriesGroupedByUser() async {
    final rows = await _client
        .from('stories_view')
        .select()
        .gte('created_at', _cutoff.toIso8601String())
        .order('created_at');

    final grouped = <String, UserStories>{};
    for (final r in rows as List) {
      final userId = r['user_id'] as String;
      final story = Story.fromMap(r);
      final firstName = r['first_name'] as String?;
      final lastName = r['last_name'] as String?;
      final avatarUrl = r['avatar_url'] as String?;

      final existing = grouped[userId];
      if (existing == null) {
        grouped[userId] = UserStories(
          userId: userId,
          userName: [firstName, lastName]
              .where((s) => s != null && s.isNotEmpty)
              .join(' '),
          userAvatarUrl:
              (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null,
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

  /// Ajouter (ou mettre à jour) une réaction à une story.
  /// `amount` sert uniquement pour les donations (gift).
  Future<void> addStoryReaction({
    required String storyId,
    required String reactionType, // 'love' | 'gift' | 'dislike'
    int amount = 1,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('story_reactions').upsert({
      'story_id': storyId,
      'user_id': userId,
      'reaction_type': reactionType,
      'amount': amount,
    }, onConflict: 'story_id,user_id');
  }

  /// Récupère les compteurs de réactions pour une story
  Future<StoryReactionCounts> getReactionCounts(String storyId) async {
    try {
      final rows = await _client
          .from('story_reactions')
          .select('reaction_type, amount')
          .eq('story_id', storyId);

      int loveCount = 0;
      int giftCount = 0;
      int dislikeCount = 0;

      for (final r in rows as List) {
        final type = r['reaction_type'] as String;
        final amount = (r['amount'] as num?)?.toInt() ?? 1;

        if (type == 'love') {
          loveCount++;
        } else if (type == 'gift') {
          giftCount += amount;
        } else if (type == 'dislike') {
          dislikeCount++;
        }
      }

      return StoryReactionCounts(
        loveCount: loveCount,
        giftCount: giftCount,
        dislikeCount: dislikeCount,
      );
    } catch (e) {
      return StoryReactionCounts(loveCount: 0, giftCount: 0, dislikeCount: 0);
    }
  }
}
