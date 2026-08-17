import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_models.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String get currentUserId => _client.auth.currentUser!.id;

  /// Compteur de vues — incrémenté côté serveur uniquement (RPC),
  /// jamais en écrivant directement sur la colonne depuis le client.
  Future<void> incrementViews(String entityId) async {
    await _client
        .rpc('increment_entity_views', params: {'p_entity_id': entityId});
  }

  Future<QotaProfile> getMyProfile() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', currentUserId)
        .single();
    return QotaProfile.fromMap(row);
  }

  /// §7 : profil PUBLIC — nom, photo, User Items publiés — consultable
  /// pour n'importe quel utilisateur, pas seulement soi-même. Passe
  /// par public_profile_view (jamais la table brute, protégée par RLS
  /// et contenant des champs privés comme l'âge).
  Future<QotaProfile> getProfileById(String userId) async {
    final row = await _client
        .from('public_profile_view')
        .select()
        .eq('id', userId)
        .single();
    return QotaProfile.fromMap(row);
  }

  Future<double> getMyWalletBalance() async {
    final row = await _client
        .from('wallets')
        .select('balance')
        .eq('user_id', currentUserId)
        .single();
    return (row['balance'] as num).toDouble();
  }

  /// §7 : User Items publiés par l'utilisateur, affichés sur son profil.
  Future<List<QotaUserItem>> getUserItems(String ownerId) async {
    final rows =
        await _client.from('user_items_view').select().eq('owner_id', ownerId);
    return (rows as List).map((r) => QotaUserItem.fromMap(r)).toList();
  }

  /// §8 : la règle (1er gratuit, ensuite payant) est appliquée côté
  /// serveur via la RPC `change_user_name` — jamais côté client.
  Future<Map<String, dynamic>> changeName({
    required String firstName,
    required String lastName,
  }) async {
    final result = await _client.rpc('change_user_name', params: {
      'p_first_name': firstName,
      'p_last_name': lastName,
    });
    return result as Map<String, dynamic>;
  }

  Future<String> uploadUserItemImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final path =
        '$currentUserId/user_items/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from('user-content').uploadBinary(path, bytes);
    return _client.storage.from('user-content').getPublicUrl(path);
  }

  /// §23-24 : image obligatoire, propriétaire = créateur, PAS de
  /// détection stricte de doublon (contrairement aux Services §19-20) —
  /// un même utilisateur peut publier plusieurs fois un item similaire.
  Future<void> createUserItem({
    required String name,
    required String imageUrl,
    String? description,
  }) async {
    await _client.from('entities').insert({
      'kind': 'user_item',
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'created_by': currentUserId,
      'owner_id': currentUserId,
      'status': 'active',
    });
  }
}
