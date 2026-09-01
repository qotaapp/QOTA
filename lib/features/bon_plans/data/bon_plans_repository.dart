import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class BonPlan {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;
  final bool active;

  BonPlan({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description,
    this.linkUrl,
    this.active = true,
  });

  factory BonPlan.fromMap(Map<String, dynamic> map) => BonPlan(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String,
        linkUrl: map['link_url'] as String?,
        active: map['active'] as bool? ?? true,
      );
}

/// Répertoire des "Bons plans" (offres/promotions éditoriales, gérées
/// par le Super Admin — contrairement aux Services/Figures, il n'y a
/// pas de contribution utilisateur ici).
class BonPlansRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<BonPlan>> getActiveBonPlans() async {
    final rows = await _client
        .from('bon_plans')
        .select()
        .eq('active', true)
        .order('order_index');
    return (rows as List).map((r) => BonPlan.fromMap(r)).toList();
  }

  Future<String> uploadImage(
      {required Uint8List bytes, required String fileExtension}) async {
    final userId = _client.auth.currentUser!.id;
    final path =
        '$userId/bon_plans/${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
    await _client.storage.from('user-content').uploadBinary(path, bytes);
    return _client.storage.from('user-content').getPublicUrl(path);
  }
}
