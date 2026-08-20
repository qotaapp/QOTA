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

  /// Un profil créé via Google Sign-In n'a jamais d'âge (Google ne le
  /// fournit pas) et peut avoir un nom vide dans de rares cas. Utilisé
  /// par AuthGate (main.dart) pour forcer le passage par
  /// CompleteProfileScreen avant Home tant que ce n'est pas complété.
  Future<bool> isProfileComplete() async {
    final row = await _client
        .from('profiles')
        .select('first_name, last_name, age')
        .eq('id', currentUserId)
        .single();
    final firstName = (row['first_name'] as String?)?.trim() ?? '';
    final lastName = (row['last_name'] as String?)?.trim() ?? '';
    return firstName.isNotEmpty && lastName.isNotEmpty && row['age'] != null;
  }

  /// Complète nom/prénom/âge — utilisé par CompleteProfileScreen après
  /// une première connexion Google (§handle_new_auth_user les avait
  /// laissés vides/nuls faute d'information fournie par Google).
  Future<void> updateBasicInfo({
    required String firstName,
    required String lastName,
    required int age,
  }) async {
    await _client.from('profiles').update({
      'first_name': firstName,
      'last_name': lastName,
      'age': age,
    }).eq('id', currentUserId);
  }

  /// Profil PUBLIC de n'importe quel utilisateur (nom + avatar
  /// uniquement) — via `public_profiles_view`, pas la table
  /// `profiles` dont la RLS interdit la lecture croisée entre
  /// utilisateurs. Utilisé quand on tape sur le nom/avatar d'un
  /// auteur de publication (Home, User Items) pour voir sa page.
  Future<PublicProfile> getPublicProfile(String userId) async {
    final row = await _client
        .from('public_profiles_view')
        .select()
        .eq('id', userId)
        .single();
    return PublicProfile.fromMap(row);
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

  /// Photo de profil. Le redimensionnement (côté `image_picker`, voir
  /// l'écran) garantit une image déjà "carrée-friendly" et légère —
  /// affichée ensuite via `BoxFit.cover` dans les CircleAvatar, donc
  /// nette et bien cadrée même en très petite taille (barre de statut).
  Future<String> uploadAvatarImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final path =
        '$currentUserId/avatar/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from('user-content').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('user-content').getPublicUrl(path);
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    await _client
        .from('profiles')
        .update({'avatar_url': avatarUrl}).eq('id', currentUserId);
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

  /// Suppression d'un User Item par son PROPRIÉTAIRE — sur son propre
  /// profil, chaque utilisateur peut supprimer ses propres
  /// publications. La RLS ("Owners delete own entities" ou
  /// équivalent) refuse déjà côté serveur toute tentative sur un item
  /// qui n'appartient pas à l'appelant, donc ce garde-fou existe
  /// même si ce bouton n'apparaissait un jour ailleurs par erreur.
  Future<void> deleteUserItem(String entityId) async {
    await _client.from('entities').delete().eq('id', entityId);
  }
}
