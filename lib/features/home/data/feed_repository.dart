import 'package:supabase_flutter/supabase_flutter.dart';

/// Représente un commentaire sur une publication.
class Comment {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.userAvatarUrl,
  });

  factory Comment.fromMap(Map<String, dynamic> map) => Comment(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        userName: map['user_name'] as String,
        userAvatarUrl: map['user_avatar_url'] as String?,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// Représente un élément du Feed, quel que soit son kind (§9).
/// ownerName n'est renseigné que pour les User Items (§23) — jamais
/// pour les Services (§18), cohérent avec le reste de l'app.
class FeedItem {
  final String id;
  final String kind; // 'service' | 'user_item'
  final String name;
  final String? description;
  final String imageUrl;
  final String? cityNameFr;
  final String? zoneNameFr;
  final String? ownerId;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final DateTime createdAt;
  final double averageScore;
  final int ratingsCount;
  final int commentsCount;
  final int viewsCount;

  FeedItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    required this.averageScore,
    required this.ratingsCount,
    required this.commentsCount,
    this.viewsCount = 0,
    this.description,
    this.cityNameFr,
    this.zoneNameFr,
    this.ownerId,
    this.ownerName,
    this.ownerAvatarUrl,
  });

  factory FeedItem.fromMap(Map<String, dynamic> map) => FeedItem(
        id: map['id'] as String,
        kind: map['kind'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String,
        cityNameFr: map['city_name_fr'] as String?,
        zoneNameFr: map['zone_name_fr'] as String?,
        ownerId: map['owner_id'] as String?,
        ownerName: map['owner_name'] as String?,
        ownerAvatarUrl: map['owner_avatar_url'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        averageScore: (map['average_score'] as num?)?.toDouble() ?? 0,
        ratingsCount: (map['ratings_count'] as num?)?.toInt() ?? 0,
        commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
        viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
      );

  String get locationLabel => [zoneNameFr, cityNameFr]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');
}

class FeedRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// §9-10 : appelle l'algorithme côté serveur (012_feed_algorithm.sql).
  /// La position de l'utilisateur est optionnelle — sans elle, la
  /// proximité est neutre et le classement repose sur fraîcheur/engagement.
  Future<List<FeedItem>> getFeed({
    double? userLat,
    double? userLng,
    int limit = 15,
    int offset = 0,
  }) async {
    final rows = await _client.rpc('get_feed', params: {
      'p_user_lat': userLat,
      'p_user_lng': userLng,
      'p_limit': limit,
      'p_offset': offset,
    });
    return (rows as List).map((r) => FeedItem.fromMap(r)).toList();
  }

  /// Récupère les commentaires d'une publication/entité
  /* Future<List<Comment>> getComments(String entityId) async {
    final rows = await _client
        .from('comments')
        .select(
            'id, user_id, user:users(name, avatar_url), content, created_at')
        .eq('entity_id', entityId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => Comment.fromMap({
              'id': r['id'] as String,
              'user_id': r['user_id'] as String,
              'user_name': (r['user'] as Map)['name'] as String,
              'user_avatar_url': (r['user'] as Map)['avatar_url'] as String?,
              'content': r['content'] as String,
              'created_at': r['created_at'] as String,
            }))
        .toList();
  }*/

  /// Ajoute un nouveau commentaire
  /*Future<Comment> addComment({
    required String entityId,
    required String content,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non authentifié');

    final response = await _client
        .from('comments')
        .insert({
          'entity_id': entityId,
          'user_id': userId,
          'content': content,
        })
        .select(
            'id, user_id, user:users(name, avatar_url), content, created_at')
        .single();

    return Comment.fromMap({
      'id': response['id'] as String,
      'user_id': response['user_id'] as String,
      'user_name': (response['user'] as Map)['name'] as String,
      'user_avatar_url': (response['user'] as Map)['avatar_url'] as String?,
      'content': response['content'] as String,
      'created_at': response['created_at'] as String,
    });
  }*/

  /// Récupère les commentaires d'une publication/entité
  /// Récupère les commentaires d'une publication/entité
  Future<List<Comment>> getComments(String entityId) async {
    try {
      final rows = await _client
          .from('comments')
          .select('id, user_id, text, created_at')
          .eq('entity_id', entityId)
          .order('created_at', ascending: false);

      /*print('✅ Commentaires récupérés: ${rows.length}');*/
      return (rows as List)
          .map((r) => Comment.fromMap({
                'id': r['id'] as String,
                'user_id': r['user_id'] as String,
                'user_name': 'Utilisateur',
                'user_avatar_url': null,
                'content': r['text'] as String,
                'created_at': r['created_at'] as String,
              }))
          .toList();
    } catch (e) {
      /*print('❌ Erreur getComments: $e');*/
      return [];
    }
  }

  /// Ajoute un nouveau commentaire
  Future<Comment?> addComment({
    required String entityId,
    required String content,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non authentifié');

      final response = await _client
          .from('comments')
          .insert({
            'entity_id': entityId,
            'user_id': userId,
            'text': content,
          })
          .select('id, user_id, text, created_at')
          .single();

      /*print('✅ Commentaire ajouté');*/
      return Comment.fromMap({
        'id': response['id'] as String,
        'user_id': response['user_id'] as String,
        'user_name': 'Utilisateur',
        'user_avatar_url': null,
        'content': response['text'] as String,
        'created_at': response['created_at'] as String,
      });
    } catch (e) {
      /*print('❌ Erreur addComment: $e');*/
      return null;
    }
  }
}
