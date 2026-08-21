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

  factory SearchResultEntity.fromMap(Map<String, dynamic> map) =>
      SearchResultEntity(
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

  String get locationLabel => [zoneNameFr, cityNameFr]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');
}

class SearchResultUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  SearchResultUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  factory SearchResultUser.fromMap(Map<String, dynamic> map) =>
      SearchResultUser(
        id: map['id'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        avatarUrl: map['avatar_url'] as String?,
      );

  String get fullName => '$firstName $lastName';
}

class SearchResultCategory {
  final String id;
  final String nameFr;
  SearchResultCategory({required this.id, required this.nameFr});

  factory SearchResultCategory.fromMap(Map<String, dynamic> map) =>
      SearchResultCategory(
          id: map['id'] as String, nameFr: map['name_fr'] as String);
}

/// Regroupe les 3 volets d'une recherche (§12), pour éviter un type
/// record trop long à faire tenir sur une seule signature de méthode.
class SearchResults {
  final List<SearchResultCategory> categories;
  final List<SearchResultEntity> entities;
  final List<SearchResultUser> users;

  const SearchResults({
    required this.categories,
    required this.entities,
    required this.users,
  });

  const SearchResults.empty()
      : categories = const [],
        entities = const [],
        users = const [];
}

class SearchRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// §12 : recherche unifiée services/lieux/contenus + catégories +
  /// utilisateurs (par prénom/nom).
  Future<SearchResults> search(
    String query, {
    double? userLat,
    double? userLng,
  }) async {
    if (query.trim().length < 2) {
      return const SearchResults.empty();
    }

    final categoriesRows = await _client
        .rpc('search_categories', params: {'p_query': query, 'p_limit': 6});
    final entitiesRows = await _client.rpc('search_entities', params: {
      'p_query': query,
      'p_user_lat': userLat,
      'p_user_lng': userLng,
      'p_limit': 30,
    });
    final usersRows = await _client
        .rpc('search_users', params: {'p_query': query, 'p_limit': 15});

    final categories = (categoriesRows as List)
        .map((r) => SearchResultCategory.fromMap(r))
        .toList();
    final entities = (entitiesRows as List)
        .map((r) => SearchResultEntity.fromMap(r))
        .toList();
    final users =
        (usersRows as List).map((r) => SearchResultUser.fromMap(r)).toList();

    return SearchResults(
      categories: categories,
      entities: entities,
      users: users,
    );
  }
}
