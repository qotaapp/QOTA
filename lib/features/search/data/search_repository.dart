import 'package:supabase_flutter/supabase_flutter.dart';

class SearchResultEntity {
  final String id;
  final String kind;
  final String name;
  final String? description;
  final String imageUrl;
  final String? cityNameFr;
  final String? zoneNameFr;
  final double averageScore;
  final int ratingsCount;
  final int commentsCount;

  SearchResultEntity({
    required this.id,
    required this.kind,
    required this.name,
    required this.imageUrl,
    required this.averageScore,
    required this.ratingsCount,
    required this.commentsCount,
    this.description,
    this.cityNameFr,
    this.zoneNameFr,
  });

  factory SearchResultEntity.fromMap(Map<String, dynamic> map) => SearchResultEntity(
        id: map['id'] as String,
        kind: map['kind'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String,
        cityNameFr: map['city_name_fr'] as String?,
        zoneNameFr: map['zone_name_fr'] as String?,
        averageScore: (map['average_score'] as num?)?.toDouble() ?? 0,
        ratingsCount: (map['ratings_count'] as num?)?.toInt() ?? 0,
        commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
      );

  String get locationLabel =>
      [zoneNameFr, cityNameFr].where((e) => e != null && e.isNotEmpty).join(', ');
}

class SearchResultCategory {
  final String id;
  final String nameFr;
  SearchResultCategory({required this.id, required this.nameFr});

  factory SearchResultCategory.fromMap(Map<String, dynamic> map) =>
      SearchResultCategory(id: map['id'] as String, nameFr: map['name_fr'] as String);
}

class SearchRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// §12 : recherche unifiée services/lieux/contenus + catégories.
  Future<(List<SearchResultCategory>, List<SearchResultEntity>)> search(
    String query, {
    double? userLat,
    double? userLng,
  }) async {
    if (query.trim().length < 2) return (<SearchResultCategory>[], <SearchResultEntity>[]);

    final categoriesRows = await _client.rpc('search_categories', params: {'p_query': query, 'p_limit': 6});
    final entitiesRows = await _client.rpc('search_entities', params: {
      'p_query': query,
      'p_user_lat': userLat,
      'p_user_lng': userLng,
      'p_limit': 30,
    });

    final categories = (categoriesRows as List).map((r) => SearchResultCategory.fromMap(r)).toList();
    final entities = (entitiesRows as List).map((r) => SearchResultEntity.fromMap(r)).toList();

    return (categories, entities);
  }
}
