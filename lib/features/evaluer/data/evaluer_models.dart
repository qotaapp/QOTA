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
  final String? icon;

  QotaCity(
      {required this.id,
      required this.stateId,
      required this.nameFr,
      required this.nameAr,
      this.icon});

  // `icon` : colonne optionnelle, absente en base tant qu'elle n'a
  // pas été ajoutée par migration — map['icon'] renvoie alors null
  // sans casser le parsing.
  factory QotaCity.fromMap(Map<String, dynamic> map) => QotaCity(
        id: map['id'] as String,
        stateId: map['state_id'] as String,
        nameFr: map['name_fr'] as String,
        nameAr: map['name_ar'] as String,
        icon: map['icon'] as String?,
      );
}

class QotaZone {
  final String id;
  final String cityId;
  final String nameFr;
  final String nameAr;
  final String? icon;

  QotaZone(
      {required this.id,
      required this.cityId,
      required this.nameFr,
      required this.nameAr,
      this.icon});

  // `icon` : même remarque que QotaCity ci-dessus.
  factory QotaZone.fromMap(Map<String, dynamic> map) => QotaZone(
        id: map['id'] as String,
        cityId: map['city_id'] as String,
        nameFr: map['name_fr'] as String,
        nameAr: map['name_ar'] as String,
        icon: map['icon'] as String?,
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

/// Catégorie À L'INTÉRIEUR d'une section admin (ex. "Vente en
/// ligne") — gérée exclusivement par le Super Admin. Sert à
/// organiser les publications de la section, comme QotaCategory
/// pour les Services.
class AdminListingCategory {
  final String id;
  final String adminListingTypeId;
  final String nameFr;
  final String nameAr;
  final bool active;
  final String? icon;

  AdminListingCategory({
    required this.id,
    required this.adminListingTypeId,
    required this.nameFr,
    required this.nameAr,
    required this.active,
    this.icon,
  });

  // `icon` : colonne optionnelle — voir remarque QotaCity ci-dessus.
  factory AdminListingCategory.fromMap(Map<String, dynamic> map) =>
      AdminListingCategory(
        id: map['id'] as String,
        adminListingTypeId: map['admin_listing_type_id'] as String,
        nameFr: map['name_fr'] as String,
        nameAr: map['name_ar'] as String,
        active: map['active'] as bool,
        icon: map['icon'] as String?,
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
  final String? categoryNameFr;
  final String? phoneNumber; // format E.164, ex: +21612345678 — public
  final double averageScore;
  final int ratingsCount;
  final int commentsCount;
  final int viewsCount;

  QotaEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.averageScore,
    required this.ratingsCount,
    required this.commentsCount,
    this.viewsCount = 0,
    this.description,
    this.cityNameFr,
    this.zoneNameFr,
    this.figureTypeNameFr,
    this.categoryNameFr,
    this.phoneNumber,
  });

  factory QotaEntity.fromMap(Map<String, dynamic> map) => QotaEntity(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String,
        cityNameFr: map['city_name_fr'] as String?,
        zoneNameFr: map['zone_name_fr'] as String?,
        figureTypeNameFr: map['figure_type_name_fr'] as String?,
        categoryNameFr: map['category_name_fr'] as String?,
        phoneNumber: map['phone_number'] as String?,
        averageScore: (map['average_score'] as num?)?.toDouble() ?? 0,
        ratingsCount: (map['ratings_count'] as num?)?.toInt() ?? 0,
        commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
        viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
      );

  String get locationLabel => [zoneNameFr, cityNameFr]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');

  // entity_cards_view ne renvoie que des publications déjà actives
  // (where status = 'active') — jamais 'pending_review' ici.
  bool get isPendingReview => false;
}
