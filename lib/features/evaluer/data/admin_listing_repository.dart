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
///
/// Chaque section peut en plus être organisée en catégories (ex.
/// "Vente en ligne"), gérées EXCLUSIVEMENT par le Super Admin —
/// contrairement aux publications elles-mêmes, ouvertes à tous.
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

  /// [activeOnly] = false pour le Super Admin (voit aussi les
  /// catégories désactivées, pour pouvoir les réactiver).
  Future<List<AdminListingCategory>> getCategories(
    String typeId, {
    bool activeOnly = true,
  }) async {
    final baseQuery = _client
        .from('admin_listing_categories')
        .select()
        .eq('admin_listing_type_id', typeId);
    final rows = activeOnly
        ? await baseQuery.eq('active', true).order('order_index')
        : await baseQuery.order('order_index');
    return (rows as List).map((r) => AdminListingCategory.fromMap(r)).toList();
  }

  Future<void> createCategory({
    required String typeId,
    required String nameFr,
    required String nameAr,
  }) async {
    await _client.from('admin_listing_categories').insert({
      'admin_listing_type_id': typeId,
      'name_fr': nameFr,
      'name_ar': nameAr,
    });
  }

  Future<void> updateCategory(
    String id, {
    required String nameFr,
    required String nameAr,
  }) async {
    await _client.from('admin_listing_categories').update({
      'name_fr': nameFr,
      'name_ar': nameAr,
    }).eq('id', id);
  }

  Future<void> toggleCategoryActive(String id, bool active) async {
    await _client
        .from('admin_listing_categories')
        .update({'active': active}).eq('id', id);
  }

  /// Peut échouer (contrainte FK) si des publications utilisent
  /// encore cette catégorie — géré côté écran par un message clair,
  /// même pattern que AdminCategoriesScreen (Services).
  Future<void> deleteCategory(String id) async {
    await _client.from('admin_listing_categories').delete().eq('id', id);
  }

  /// [categoryId] optionnel : filtre sur une catégorie précise de la
  /// section (null = toute la section, comportement d'origine).
  Future<List<QotaEntity>> getListings(String typeId,
      {String? categoryId}) async {
    final baseQuery = _client
        .from('entity_cards_view')
        .select()
        .eq('kind', 'admin_listing')
        .eq('admin_listing_type_id', typeId);
    final rows = categoryId != null
        ? await baseQuery.eq('admin_listing_category_id', categoryId)
        : await baseQuery;
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
  ///
  /// [categoryId] optionnel : rattache la publication à une catégorie
  /// de la section (ex. sous-rubrique de "Vente en ligne").
  Future<void> createListing({
    required String name,
    required String imageUrl,
    required String typeId,
    String? categoryId,
    String? description,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('entities').insert({
      'kind': 'admin_listing',
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'admin_listing_type_id': typeId,
      'admin_listing_category_id': categoryId,
      'created_by': userId,
      'owner_id': null,
      'status': 'pending_review',
    });
  }
}
