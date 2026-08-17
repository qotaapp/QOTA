/// Version publique d'un profil — nom + avatar uniquement (via
/// `public_profiles_view`), consultable pour N'IMPORTE QUEL
/// utilisateur (contrairement à QotaProfile, réservé au sien).
class PublicProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  PublicProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  factory PublicProfile.fromMap(Map<String, dynamic> map) => PublicProfile(
        id: map['id'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        avatarUrl: map['avatar_url'] as String?,
      );

  String get fullName => '$firstName $lastName';
}

class QotaProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final int nameChangeCount;

  QotaProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nameChangeCount,
    this.avatarUrl,
  });

  factory QotaProfile.fromMap(Map<String, dynamic> map) => QotaProfile(
        id: map['id'] as String,
        firstName: map['first_name'] as String,
        lastName: map['last_name'] as String,
        avatarUrl: map['avatar_url'] as String?,
        nameChangeCount: (map['name_change_count'] as num?)?.toInt() ?? 0,
      );

  String get fullName => '$firstName $lastName';
}

/// §23 : un User Item représente quelque chose que l'utilisateur possède,
/// crée ou souhaite présenter — le propriétaire est TOUJOURS affiché
/// publiquement (contrairement aux Services, §18).
class QotaUserItem {
  final String id;
  final String name;
  final String? description;
  final String imageUrl;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatarUrl;
  final double averageScore;
  final int ratingsCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;

  QotaUserItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.averageScore,
    required this.ratingsCount,
    required this.commentsCount,
    required this.createdAt,
    this.viewsCount = 0,
    this.description,
    this.ownerAvatarUrl,
  });

  factory QotaUserItem.fromMap(Map<String, dynamic> map) => QotaUserItem(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String,
        ownerId: map['owner_id'] as String? ?? '',
        ownerName: map['owner_name'] as String? ?? '',
        ownerAvatarUrl: map['owner_avatar_url'] as String?,
        averageScore: (map['average_score'] as num?)?.toDouble() ?? 0,
        ratingsCount: (map['ratings_count'] as num?)?.toInt() ?? 0,
        commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
        viewsCount: (map['views_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
