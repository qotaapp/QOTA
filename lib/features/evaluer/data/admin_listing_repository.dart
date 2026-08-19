import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'evaluer_models.dart';

/// Sections du menu Évaluer alimentées EXCLUSIVEMENT par le Super
/// Admin (ou un modérateur avec la permission 'moderate_content') :
/// "Chaînes et programmes", "Vente en ligne", "Autres". Contrairement
/// à EvaluerRepository (Services) et FiguresRepository (Figures),
/// jamais un utilisateur ordinaire — la RLS (§022) l'interdit aussi
/// côté base, ceci n'est qu'un confort côté app (masquer le "+").
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
      'status': 'active',
    });
  }
}
