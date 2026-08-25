import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'evaluer_models.dart';

/// Sections du menu Évaluer — "Chaînes et programmes", "Vente en
/// ligne", "Autres". Comme EvaluerRepository (Services) et
/// FiguresRepository (Figures), n'importe quel utilisateur peut
/// publier ici : l'entrée entre en 'pending_review' et n'apparaît
/// nulle part (Home, listes, recherche) tant que le Super Admin (ou
/// un modérateur avec la permission 'moderate_content') ne l'a pas
/// approuvée depuis le Dashboard.
class AdminListingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AdminListingType?> getTypeBySlug(String slug) async {
    final rows = await _client
        .from('admin_listing_types')
        .select()
        .eq('slug', slug)
        .eq('active', true)
        .limit(1);
    if ((rows as List).isEmpty) {
      return null;
    }
    return AdminListingType.fromMap(rows.first);
  }

  Future<List<QotaEntity>> getListings(String typeId) async {
    final rows = await _client
        .from('entity_cards_view')
        .select()
        .eq('kind', 'admin_listing')
        .eq('admin_listing_type_id', typeId);
    return (rows as List).map((r) => QotaEntity.fromMap(r)).toList();
  }

  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path =
        '$userId/admin_listings/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from('user-content').uploadBinary(path, bytes);
    return _client.storage.from('user-content').getPublicUrl(path);
  }

  /// Le profil de la personne ayant publié n'est pas affiché
  /// publiquement — mêmes règles que pour une Service (§18) ou une
  /// Figure (§35). Modération obligatoire : invisible partout tant
  /// que non approuvée par le Super Admin.
  Future<void> createListing({
    required String name,
    required String imageUrl,
    required String typeId,
    String? description,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('entities').insert({
      'kind': 'admin_listing',
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'admin_listing_type_id': typeId,
      'created_by': userId,
      'owner_id': null,
      'status': 'pending_review',
    });
  }
}
