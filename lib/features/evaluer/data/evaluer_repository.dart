import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'evaluer_models.dart';

/// §14-19 : toute la hiérarchie est dynamique, jamais codée en dur.
class EvaluerRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<QotaState>> getStates() async {
    final rows = await _client
        .from('states')
        .select()
        .eq('active', true)
        .order('order_index');
    return (rows as List).map((r) => QotaState.fromMap(r)).toList();
  }

  Future<List<QotaCity>> getCities(String stateId) async {
    final rows = await _client
        .from('cities')
        .select()
        .eq('state_id', stateId)
        .eq('active', true)
        .order('order_index');
    return (rows as List).map((r) => QotaCity.fromMap(r)).toList();
  }

  Future<List<QotaZone>> getZones(String cityId) async {
    final rows = await _client
        .from('zones')
        .select()
        .eq('city_id', cityId)
        .eq('active', true)
        .order('order_index');
    return (rows as List).map((r) => QotaZone.fromMap(r)).toList();
  }

  /// §16 : catégories propres à CETTE ville (table de liaison
  /// category_cities, gérée par le Super Admin) — plus une liste
  /// globale partagée par toutes les villes.
  Future<List<QotaCategory>> getCategories(String cityId) async {
    final rows = await _client
        .from('category_cities')
        .select('categories!inner(*)')
        .eq('city_id', cityId)
        .eq('categories.active', true)
        .order('order_index', referencedTable: 'categories');
    return (rows as List)
        .map((r) =>
            QotaCategory.fromMap(r['categories'] as Map<String, dynamic>))
        .toList();
  }

  /// §18 : liste des Services d'une catégorie, dans une zone (ou ville
  /// si aucune zone n'a été sélectionnée). Utilise entity_cards_view
  /// pour ne jamais exposer created_by/owner_id.
  Future<List<QotaEntity>> getServices({
    required String categoryId,
    required String cityId,
    String? zoneId,
  }) async {
    var query = _client
        .from('entity_cards_view')
        .select()
        .eq('category_id', categoryId)
        .eq('city_id', cityId)
        .eq('kind', 'service');

    if (zoneId != null) {
      query = query.eq('zone_id', zoneId);
    }

    final rows = await query;
    return (rows as List).map((r) => QotaEntity.fromMap(r)).toList();
  }

  /// §19-20 : détection de doublon avant création d'une Service.
  /// Combine similarité de nom (pg_trgm) + proximité (ville/zone).
  Future<List<QotaEntity>> findPotentialDuplicates({
    required String name,
    required String cityId,
    String? zoneId,
  }) async {
    var query = _client
        .from('entity_cards_view')
        .select()
        .eq('city_id', cityId)
        .eq('kind', 'service')
        .ilike('name', '%$name%');

    if (zoneId != null) {
      query = query.eq('zone_id', zoneId);
    }

    final rows = await query.limit(5);
    return (rows as List).map((r) => QotaEntity.fromMap(r)).toList();
  }

  /// §26 : récupère une entité unique pour la fiche Service Details.
  Future<QotaEntity?> getEntityById(String entityId) async {
    final rows = await _client
        .from('entity_cards_view')
        .select()
        .eq('id', entityId)
        .limit(1);
    if ((rows as List).isEmpty) {
      return null;
    }
    return QotaEntity.fromMap(rows.first);
  }

  /// §19 : image obligatoire — upload dans le bucket `user-content`,
  /// sous le dossier de l'utilisateur (policy RLS §6 : {user_id}/...).
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path =
        '$userId/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';

    await _client.storage.from('user-content').uploadBinary(path, bytes);
    return _client.storage.from('user-content').getPublicUrl(path);
  }

  /// §19-21 : création d'une Service. Depuis la modération obligatoire,
  /// la publication n'est plus immédiate : la Service entre en
  /// 'pending_review' et n'apparaît nulle part publiquement (Home,
  /// recherche, listes) tant que le Super Admin (ou un modérateur
  /// avec la permission 'moderate_content') ne l'a pas approuvée.
  /// Filet de sécurité redondant côté base (trigger, §019) : même si
  /// ce champ était altéré côté client, le statut serait re-forcé.
  Future<String> createService({
    required String name,
    required String imageUrl,
    required String categoryId,
    required String stateId,
    required String cityId,
    String? zoneId,
    double? latitude,
    double? longitude,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final row = await _client
        .from('entities')
        .insert({
          'kind': 'service',
          'name': name,
          'image_url': imageUrl,
          'category_id': categoryId,
          'state_id': stateId,
          'city_id': cityId,
          'zone_id': zoneId,
          'latitude': latitude,
          'longitude': longitude,
          'created_by': userId,
          'owner_id': userId,
          'status': 'pending_review',
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  /// §20/§22 : demande de propriété sur une Service existante.
  Future<void> requestOwnership({
    required String entityId,
    String? message,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('ownership_requests').insert({
      'entity_id': entityId,
      'requester_id': userId,
      'status': 'pending',
      'message': message,
    });
  }
}
