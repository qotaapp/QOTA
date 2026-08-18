import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../evaluer/data/evaluer_models.dart';

class FiguresRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// §35 : types gérés par le Super Admin (extensibles sans code).
  Future<List<FigureType>> getFigureTypes() async {
    final rows = await _client
        .from('figure_types')
        .select()
        .eq('active', true)
        .order('order_index');
    return (rows as List).map((r) => FigureType.fromMap(r)).toList();
  }

  Future<List<QotaEntity>> getFigures(String figureTypeId) async {
    final rows = await _client
        .from('entity_cards_view')
        .select()
        .eq('kind', 'public_figure')
        .eq('figure_type_id', figureTypeId);
    return (rows as List).map((r) => QotaEntity.fromMap(r)).toList();
  }

  Future<List<QotaEntity>> findPotentialDuplicates(String name) async {
    final rows = await _client
        .from('entity_cards_view')
        .select()
        .eq('kind', 'public_figure')
        .ilike('name', '%$name%')
        .limit(5);
    return (rows as List).map((r) => QotaEntity.fromMap(r)).toList();
  }

  Future<String> uploadImage(
      {required Uint8List bytes, required String fileExtension}) async {
    final userId = _client.auth.currentUser!.id;
    final path =
        '$userId/figures/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from('user-content').uploadBinary(path, bytes);
    return _client.storage.from('user-content').getPublicUrl(path);
  }

  /// §35-36 : le profil de la personne ayant ajouté la Figure n'est
  /// pas affiché publiquement — mêmes règles que pour une Service (§18).
  Future<void> createFigure({
    required String name,
    required String imageUrl,
    required String figureTypeId,
    String? description,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('entities').insert({
      'kind': 'public_figure',
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'figure_type_id': figureTypeId,
      'created_by': userId,
      'owner_id':
          null, // une figure publique n'a pas de "propriétaire" utilisateur
      // Modération obligatoire (comme les Services) : invisible
      // partout (Home, listes, recherche) tant que non approuvée par
      // le Super Admin depuis le Dashboard.
      'status': 'pending_review',
    });
  }
}
