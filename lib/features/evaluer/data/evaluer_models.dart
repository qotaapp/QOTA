/// Modèles légers reflétant le schéma Supabase (qota_schema.sql).
/// name_fr/name_ar : jamais de texte codé en dur (§2).
library;

class QotaState {
  final String id;
  final String nameFr;
  final String nameAr;

  QotaState({required this.id, required this.nameFr, required this.nameAr});

  factory QotaState.fromMap(Map<String, dynamic> map) => QotaState(
        id: map['id'] as String,
        nameFr: map['name_fr'] as String,
        nameAr: map['name_ar'] as String,
      );
}

class QotaCity {
  final String id;
  final String stateId;
  final String nameFr;
  final String nameAr;

  QotaCity(
      {required this.id,
      required this.stateId,
      required this.nameFr,
      required this.nameAr});

  factory QotaCity.fromMap(Map<String, dynamic> map) => QotaCity(
        id: map['id'] as String,
        stateId: map['state_id'] as String,
        nameFr: map['name_fr'] as String,
        nameAr: map['name_ar'] as String,
      );
}

class QotaZone {
  final String id;
  final String cityId;
  final String nameFr;
  final String nameAr;

  QotaZone(
      {required this.id,
      required this.cityId,
      required this.nameFr,
      required this.nameAr});

  factory QotaZone.fromMap(Map<String, dynamic> map) => QotaZone(
        id: map['id'] as String,
        cityId: map['city_id'] as String,
        nameFr: map['name_fr'] as String,
        nameAr: map['name_ar'] as String,
      );
}

class QotaCategory {
  final String id;
  final String nameFr;
  final String nameAr;
  final String? icon;

  QotaCategory(
      {required this.id,
      required this.nameFr,
      required this.nameAr,
      this.icon});

  factory QotaCategory.fromMap(Map<String, dynamic> map) => QotaCategory(
        id: map['id'] as String,
        nameFr: map['name_fr'] as String,
        nameAr: map['name_ar'] as String,
        icon: map['icon'] as String?,
      );
}

/// §35 : types de Figures Publiques, gérés par le Super Admin.
class FigureType {
  final String id;
  final String nameFr;
  final String nameAr;

  FigureType({required this.id, required this.nameFr, required this.nameAr});

  factory FigureType.fromMap(Map<String, dynamic> map) => FigureType(
        id: map['id'] as String,
        nameFr: map['name_fr'] as String,
        nameAr: map['name_ar'] as String,
      );
}

/// Section du menu Évaluer alimentée exclusivement par le Super Admin
/// (ou un modérateur avec la permission 'moderate_content') : "Chaînes
/// et programmes", "Vente en ligne", "Autres" — identifiées par un
/// `slug` stable (jamais l'UUID, qui varie d'un environnement à l'autre).
class AdminListingType {
  final String id;
  final String slug;
  final String nameFr;
  final String nameAr;

  AdminListingType({
    required this.id,
    required this.slug,
    required this.nameFr,
    required this.nameAr,
  });

  factory AdminListingType.fromMap(Map<String, dynamic> map) =>
      AdminListingType(
        id: map['id'] as String,
        slug: map['slug'] as String,
        nameFr: map['name_fr'] as String,
        nameAr: map['name_ar'] as String,
      );
}

class QotaEntity {
  final String id;
  final String name;
  final String? description;
  final String imageUrl;
  final String? cityNameFr;
  final String? zoneNameFr;
  final String? figureTypeNameFr;
  final double averageScore;
  final int ratingsCount;
  final int commentsCount;
  final int viewsCount;
  final String status;
  final String? createdBy;

  QotaEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.averageScore,
    required this.ratingsCount,
    required this.commentsCount,
    required this.status,
    this.viewsCount = 0,
    this.description,
    this.cityNameFr,
    this.zoneNameFr,
    this.figureTypeNameFr,
    this.createdBy,
  });

  factory QotaEntity.fromMap(Map<String, dynamic> map) => QotaEntity(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String,
        cityNameFr: map['city_name_fr'] as String?,
        zoneNameFr: map['zone_name_fr'] as String?,
        figureTypeNameFr: map['figure_type_name_fr'] as String?,
        averageScore: (map['average_score'] as num?)?.toDouble() ?? 0,
        ratingsCount: (map['ratings_count'] as num?)?.toInt() ?? 0,
        commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
        viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
        status: map['status'] as String? ?? 'active',
        createdBy: map['created_by'] as String?,
      );

  /// N'est vrai que pour SON créateur — entity_cards_view ne renvoie
  /// jamais une Service pending_review d'un autre utilisateur, donc
  /// ce flag est sûr à utiliser tel quel pour afficher le badge
  /// "En attente" côté Dart, sans re-vérification d'identité.
  bool get isPendingReview => status == 'pending_review';

  String get locationLabel => [zoneNameFr, cityNameFr]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');
}
