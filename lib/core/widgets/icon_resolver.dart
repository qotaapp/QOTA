import 'package:flutter/material.dart';

/// Résout la valeur du champ `icon` (categories/villes/zones, rempli
/// par le Super Admin) en widget affichable. Tant que ce champ n'est
/// pas encore renseigné en base, `fallback` est utilisé automatiquement
/// — aucune modification de code nécessaire le jour où il le sera.
///
/// Formats acceptés dans `iconValue`, essayés dans cet ordre :
/// 1. Emoji ou caractère isolé (ex: "🍴") -> affiché tel quel
/// 2. Nom d'icône Material connu (ex: "restaurant") -> IconData mappé
/// 3. Sinon (null, vide, ou nom non reconnu) -> `fallback`
Widget resolveEntityIcon({
  required String? iconValue,
  required IconData fallback,
  double size = 22,
  Color? color,
}) {
  if (iconValue == null || iconValue.trim().isEmpty) {
    return Icon(fallback, size: size, color: color);
  }

  final value = iconValue.trim();

  // Un nom d'icône Material valide ne contient que des lettres
  // minuscules et des underscores — tout le reste (emoji compris)
  // est donc forcément autre chose, à afficher tel quel.
  final looksLikeIconName = RegExp(r'^[a-z_]+$').hasMatch(value);
  if (!looksLikeIconName) {
    return Text(value, style: TextStyle(fontSize: size));
  }

  final mapped = materialIconsByName[value];
  return Icon(mapped ?? fallback, size: size, color: color);
}

/// Correspondance nom -> IconData pour les catégories/lieux les plus
/// courants. À étendre librement si le Super Admin utilise d'autres
/// noms côté back-office — un nom absent de cette table retombe
/// simplement sur l'icône générique du contexte (voir `fallback`).
const materialIconsByName = <String, IconData>{
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'local_bar': Icons.local_bar,
  'store': Icons.store,
  'local_hospital': Icons.local_hospital,
  'school': Icons.school,
  'home': Icons.home,
  'work': Icons.work,
  'fitness_center': Icons.fitness_center,
  'spa': Icons.spa,
  'local_taxi': Icons.local_taxi,
  'directions_car': Icons.directions_car,
  'hotel': Icons.hotel,
  'shopping_bag': Icons.shopping_bag,
  'local_grocery_store': Icons.local_grocery_store,
  'tv': Icons.tv,
  'movie': Icons.movie,
  'sports_soccer': Icons.sports_soccer,
  'sports_basketball': Icons.sports_basketball,
  'pets': Icons.pets,
  'local_florist': Icons.local_florist,
  'local_pharmacy': Icons.local_pharmacy,
  'local_gas_station': Icons.local_gas_station,
  'local_library': Icons.local_library,
  'museum': Icons.museum,
  'beach_access': Icons.beach_access,
  'park': Icons.park,
  'church': Icons.church,
  'person': Icons.person,
  'groups': Icons.groups,
  'campaign': Icons.campaign,
  'star': Icons.star,
  'location_city': Icons.location_city,
  'map': Icons.map,
  'category': Icons.category,
};
