import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOwnershipRequest {
  final String id;
  final String entityId;
  final String entityName;
  final String requesterName;
  final String? message;
  final DateTime createdAt;

  AdminOwnershipRequest({
    required this.id,
    required this.entityId,
    required this.entityName,
    required this.requesterName,
    required this.createdAt,
    this.message,
  });

  factory AdminOwnershipRequest.fromMap(Map<String, dynamic> map) =>
      AdminOwnershipRequest(
        id: map['id'] as String,
        entityId: map['entity_id'] as String,
        entityName: map['entity_name'] as String? ?? '',
        requesterName: map['requester_name'] as String? ?? '',
        message: map['message'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class AdminCoinPurchaseRequest {
  final String id;
  final String userName;
  final double amount;
  final DateTime createdAt;

  AdminCoinPurchaseRequest({
    required this.id,
    required this.userName,
    required this.amount,
    required this.createdAt,
  });

  factory AdminCoinPurchaseRequest.fromMap(Map<String, dynamic> map) =>
      AdminCoinPurchaseRequest(
        id: map['id'] as String,
        userName: map['user_name'] as String? ?? '',
        amount: (map['amount'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// Publication (Service ou Figure publique) en file de modération —
/// JAMAIS un User Item, exclu par construction de toutes les requêtes
/// ci-dessous (§ "sauf ce qu'ils ajoutent dans leurs profils personnels").
class AdminModeratableEntity {
  final String id;
  final String kind; // 'service' | 'public_figure'
  final String name;
  final String? description;
  final String imageUrl;
  final String status; // 'pending_review' | 'active' | 'rejected'
  final String creatorName;
  final DateTime createdAt;

  AdminModeratableEntity({
    required this.id,
    required this.kind,
    required this.name,
    required this.imageUrl,
    required this.status,
    required this.creatorName,
    required this.createdAt,
    this.description,
  });

  factory AdminModeratableEntity.fromMap(Map<String, dynamic> map) {
    final creator = map['profiles'] as Map<String, dynamic>?;
    return AdminModeratableEntity(
      id: map['id'] as String,
      kind: map['kind'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String,
      status: map['status'] as String,
      creatorName: creator != null
          ? '${creator['first_name']} ${creator['last_name']}'
          : '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Un modérateur avec son (ou ses) rôle(s) bien déterminé(s) — jamais
/// un accès total par défaut, uniquement les permissions accordées.
class AdminModerator {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final List<String> permissions;

  AdminModerator({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.permissions,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';

  factory AdminModerator.fromMap(Map<String, dynamic> map) => AdminModerator(
        id: map['id'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        avatarUrl: map['avatar_url'] as String?,
        permissions:
            (map['permissions'] as List?)?.whereType<String>().toList() ??
                const [],
      );
}

/// Résultat de recherche d'un utilisateur par e-mail (pour le désigner
/// modérateur) — jamais d'accès direct à auth.users côté client.
class AdminUserSearchResult {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  AdminUserSearchResult({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';

  factory AdminUserSearchResult.fromMap(Map<String, dynamic> map) =>
      AdminUserSearchResult(
        id: map['id'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        avatarUrl: map['avatar_url'] as String?,
      );
}

class AdminRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isCurrentUserSuperAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }
    final rows = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', userId)
        .eq('role', 'super_admin');
    return (rows as List).isNotEmpty;
  }

  /// Permissions du modérateur actuellement connecté (vide si aucune,
  /// vide aussi pour un simple utilisateur). Un Super Admin n'a pas
  /// besoin d'y figurer : il a toujours accès à tout (voir
  /// `has_permission` côté SQL).
  Future<Set<String>> getMyModeratorPermissions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return {};
    }
    final rows = await _client
        .from('moderator_permissions')
        .select('permission')
        .eq('user_id', userId);
    return (rows as List).map((r) => r['permission'] as String).toSet();
  }

  // ---------------- États (§14) ----------------

  Future<List<Map<String, dynamic>>> getAllStates() async {
    final rows = await _client.from('states').select().order('order_index');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createState(
      {required String nameFr, required String nameAr}) async {
    await _client.from('states').insert({'name_fr': nameFr, 'name_ar': nameAr});
  }

  Future<void> updateState(String id,
      {required String nameFr, required String nameAr}) async {
    await _client
        .from('states')
        .update({'name_fr': nameFr, 'name_ar': nameAr}).eq('id', id);
  }

  Future<void> toggleStateActive(String id, bool active) async {
    await _client.from('states').update({'active': active}).eq('id', id);
  }

  // ---------------- Catégories (§16) ----------------

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final rows = await _client.from('categories').select().order('order_index');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createCategory(
      {required String nameFr, required String nameAr, String? icon}) async {
    await _client
        .from('categories')
        .insert({'name_fr': nameFr, 'name_ar': nameAr, 'icon': icon});
  }

  Future<void> updateCategory(String id,
      {required String nameFr, required String nameAr}) async {
    await _client
        .from('categories')
        .update({'name_fr': nameFr, 'name_ar': nameAr}).eq('id', id);
  }

  Future<void> toggleCategoryActive(String id, bool active) async {
    await _client.from('categories').update({'active': active}).eq('id', id);
  }

  /// Catégories propres à une ville (§029) — les ids déjà associés.
  Future<Set<String>> getCityCategoryIds(String cityId) async {
    final rows = await _client
        .from('category_cities')
        .select('category_id')
        .eq('city_id', cityId);
    return (rows as List).map((r) => r['category_id'] as String).toSet();
  }

  Future<void> addCategoryToCity(
      {required String cityId, required String categoryId}) async {
    await _client
        .from('category_cities')
        .insert({'city_id': cityId, 'category_id': categoryId});
  }

  Future<void> removeCategoryFromCity(
      {required String cityId, required String categoryId}) async {
    await _client
        .from('category_cities')
        .delete()
        .eq('city_id', cityId)
        .eq('category_id', categoryId);
  }

  // ---------------- Ownership Requests (§20, §22) ----------------

  Future<List<AdminOwnershipRequest>> getPendingOwnershipRequests() async {
    final rows = await _client
        .from('ownership_requests')
        .select(
            'id, entity_id, message, created_at, entities(name), profiles(first_name, last_name)')
        .eq('status', 'pending')
        .order('created_at');

    return (rows as List).map((r) {
      final entity = r['entities'] as Map<String, dynamic>?;
      final profile = r['profiles'] as Map<String, dynamic>?;
      return AdminOwnershipRequest.fromMap({
        ...r,
        'entity_name': entity?['name'],
        'requester_name': profile != null
            ? '${profile['first_name']} ${profile['last_name']}'
            : null,
      });
    }).toList();
  }

  Future<void> decideOwnershipRequest(String requestId, bool approve) async {
    await _client.rpc('decide_ownership_request', params: {
      'p_request_id': requestId,
      'p_approve': approve,
    });
  }

  // ---------------- Coin Purchase Requests (§3) ----------------

  Future<List<AdminCoinPurchaseRequest>>
      getPendingCoinPurchaseRequests() async {
    final rows = await _client
        .from('coin_purchase_requests')
        .select('id, amount, created_at, profiles(first_name, last_name)')
        .eq('status', 'pending')
        .order('created_at');

    return (rows as List).map((r) {
      final profile = r['profiles'] as Map<String, dynamic>?;
      return AdminCoinPurchaseRequest.fromMap({
        ...r,
        'user_name': profile != null
            ? '${profile['first_name']} ${profile['last_name']}'
            : null,
      });
    }).toList();
  }

  Future<void> approveCoinPurchase(String requestId) async {
    await _client
        .rpc('approve_coin_purchase', params: {'p_request_id': requestId});
  }

  Future<void> rejectCoinPurchase(String requestId, {String? note}) async {
    await _client.rpc('reject_coin_purchase',
        params: {'p_request_id': requestId, 'p_note': note});
  }

  /// Communication avec le demandeur (négocier la méthode de
  /// paiement) — via une notification, sans changer le statut de la
  /// demande. Peut être appelée plusieurs fois avant la décision finale.
  Future<void> sendCoinPurchaseMessage(String requestId, String message) async {
    await _client.rpc('send_coin_purchase_message',
        params: {'p_request_id': requestId, 'p_message': message});
  }

  // ---------------- Villes ----------------

  Future<List<Map<String, dynamic>>> getCitiesForState(String stateId) async {
    final rows = await _client
        .from('cities')
        .select()
        .eq('state_id', stateId)
        .order('order_index');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createCity(
      {required String stateId,
      required String nameFr,
      required String nameAr}) async {
    await _client
        .from('cities')
        .insert({'state_id': stateId, 'name_fr': nameFr, 'name_ar': nameAr});
  }

  Future<void> updateCity(String id,
      {required String nameFr, required String nameAr}) async {
    await _client
        .from('cities')
        .update({'name_fr': nameFr, 'name_ar': nameAr}).eq('id', id);
  }

  Future<void> toggleCityActive(String id, bool active) async {
    await _client.from('cities').update({'active': active}).eq('id', id);
  }

  Future<void> deleteCity(String id) async {
    await _client.from('cities').delete().eq('id', id);
  }

  // ---------------- Zones ----------------

  Future<List<Map<String, dynamic>>> getZonesForCity(String cityId) async {
    final rows = await _client
        .from('zones')
        .select()
        .eq('city_id', cityId)
        .order('order_index');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createZone(
      {required String cityId,
      required String nameFr,
      required String nameAr}) async {
    await _client
        .from('zones')
        .insert({'city_id': cityId, 'name_fr': nameFr, 'name_ar': nameAr});
  }

  Future<void> updateZone(String id,
      {required String nameFr, required String nameAr}) async {
    await _client
        .from('zones')
        .update({'name_fr': nameFr, 'name_ar': nameAr}).eq('id', id);
  }

  Future<void> toggleZoneActive(String id, bool active) async {
    await _client.from('zones').update({'active': active}).eq('id', id);
  }

  Future<void> deleteZone(String id) async {
    await _client.from('zones').delete().eq('id', id);
  }

  // ---------------- Modération des publications ----------------
  // Toujours limitée à kind in ('service', 'public_figure') — un
  // User Item (contenu du profil personnel) n'apparaît JAMAIS ici,
  // ni dans la file d'attente ni dans la liste "publiées".

  Future<List<AdminModeratableEntity>> getPendingEntities() async {
    final rows = await _client
        .from('entities')
        .select(
            'id, kind, name, description, image_url, status, created_at, profiles!entities_created_by_fkey(first_name, last_name)')
        .inFilter('kind', ['service', 'public_figure'])
        .eq('status', 'pending_review')
        .order('created_at');
    return (rows as List)
        .map((r) => AdminModeratableEntity.fromMap(r))
        .toList();
  }

  Future<List<AdminModeratableEntity>> getPublishedEntities() async {
    final rows = await _client
        .from('entities')
        .select(
            'id, kind, name, description, image_url, status, created_at, profiles!entities_created_by_fkey(first_name, last_name)')
        .inFilter('kind', ['service', 'public_figure'])
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => AdminModeratableEntity.fromMap(r))
        .toList();
  }

  Future<void> approveEntity(String entityId) async {
    await _client
        .from('entities')
        .update({'status': 'active'}).eq('id', entityId);
  }

  Future<void> rejectEntity(String entityId) async {
    await _client
        .from('entities')
        .update({'status': 'rejected'}).eq('id', entityId);
  }

  /// Suppression définitive — pour une publication déjà en ligne qui
  /// enfreint les règles, pas seulement une demande en attente.
  Future<void> deleteEntity(String entityId) async {
    await _client.from('entities').delete().eq('id', entityId);
  }

  // ---------------- Modérateurs (rôles bien déterminés) ----------------

  Future<List<AdminModerator>> getModerators() async {
    final rows = await _client.from('moderators_view').select();
    return (rows as List).map((r) => AdminModerator.fromMap(r)).toList();
  }

  /// Introuvable dans auth.users -> null. Restreint au Super Admin
  /// côté SQL (voir `admin_find_user_by_email`).
  Future<AdminUserSearchResult?> findUserByEmail(String email) async {
    final rows = await _client
        .rpc('admin_find_user_by_email', params: {'p_email': email});
    final list = rows as List;
    if (list.isEmpty) {
      return null;
    }
    return AdminUserSearchResult.fromMap(list.first as Map<String, dynamic>);
  }

  /// Attribue le rôle 'moderator' (idempotent) puis remplace
  /// intégralement son jeu de permissions par `permissions` — un
  /// modérateur n'a JAMAIS plus que ce qui est explicitement coché ici.
  Future<void> setModerator(
      {required String userId, required Set<String> permissions}) async {
    await _client.from('user_roles').upsert(
      {'user_id': userId, 'role': 'moderator'},
      onConflict: 'user_id,role',
    );

    await _client.from('moderator_permissions').delete().eq('user_id', userId);

    if (permissions.isNotEmpty) {
      await _client.from('moderator_permissions').insert(
            permissions
                .map((p) => {'user_id': userId, 'permission': p})
                .toList(),
          );
    }
  }

  /// Retire entièrement le rôle modérateur (et donc toutes ses
  /// permissions, supprimées en cascade côté base).
  Future<void> revokeModerator(String userId) async {
    await _client
        .from('user_roles')
        .delete()
        .eq('user_id', userId)
        .eq('role', 'moderator');
  }
}
