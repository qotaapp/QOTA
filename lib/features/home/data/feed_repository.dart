import 'package:supabase_flutter/supabase_flutter.dart';

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

  FeedItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    required this.averageScore,
    required this.ratingsCount,
    required this.commentsCount,
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
}
