import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class BonPlan {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;
  final bool active;
  final String? cityId;
  final String? zoneId;

  BonPlan({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description,
    this.linkUrl,
    this.active = true,
    this.cityId,
    this.zoneId,
  });

  factory BonPlan.fromMap(Map<String, dynamic> map) => BonPlan(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String,
        linkUrl: map['link_url'] as String?,
        active: map['active'] as bool? ?? true,
        cityId: map['city_id'] as String?,
        zoneId: map['zone_id'] as String?,
      );

  /// Un Bon Plan sans ville/zone est national — visible partout.
  bool get isNational => cityId == null && zoneId == null;
}

/// Ville détectée par géolocalisation, mise en correspondance avec
/// notre propre répertoire (states/cities/zones) — pas juste un nom
/// brut renvoyé par le service de géocodage.
class DetectedCity {
  final String id;
  final String nameFr;
  DetectedCity({required this.id, required this.nameFr});
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

  /// Toutes les villes actives (toutes régions confondues) — pour le
  /// choix manuel de secours quand la détection GPS échoue ou que le
  /// visiteur préfère choisir lui-même.
  Future<List<DetectedCity>> getAllActiveCities() async {
    final rows =
        await _client.from('cities').select('id, name_fr').eq('active', true);
    return (rows as List)
        .map((r) =>
            DetectedCity(id: r['id'] as String, nameFr: r['name_fr'] as String))
        .toList();
  }

  /// Reverse geocoding via Nominatim (OpenStreetMap) — fonctionne sur
  /// toutes les plateformes, y compris le web (contrairement au
  /// package `geocoding`, qui n'est pas supporté sur Flutter Web).
  /// Le nom de ville renvoyé est ensuite mis en correspondance (par
  /// nom) avec notre propre table `cities` : si aucune ville connue
  /// ne correspond, retourne `null` (le visiteur peut alors choisir
  /// manuellement).
  Future<DetectedCity?> detectCity(double latitude, double longitude) async {
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&accept-language=fr');
    final response = await http.get(uri, headers: {
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) {
      return null;
    }

    // Nominatim ne renvoie pas un champ "ville" unique et fiable
    // selon les pays — on tente plusieurs clés, de la plus précise
    // à la plus large.
    final candidates = [
      address['city'],
      address['town'],
      address['municipality'],
      address['county'],
      address['state_district'],
    ].whereType<String>().toList();

    if (candidates.isEmpty) {
      return null;
    }

    final cities = await getAllActiveCities();
    for (final candidate in candidates) {
      for (final city in cities) {
        if (_normalize(city.nameFr) == _normalize(candidate)) {
          return city;
        }
      }
    }
    // Correspondance partielle en dernier recours (ex: "Tunis" dans
    // "Tunis Ville").
    for (final candidate in candidates) {
      for (final city in cities) {
        if (_normalize(candidate).contains(_normalize(city.nameFr)) ||
            _normalize(city.nameFr).contains(_normalize(candidate))) {
          return city;
        }
      }
    }
    return null;
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâ]'), 'a')
      .trim();
}
