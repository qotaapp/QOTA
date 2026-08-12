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
}
