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
  final String ownerName;
  final double averageScore;
  final int ratingsCount;
  final int commentsCount;
  final DateTime createdAt;

  QotaUserItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.ownerName,
    required this.averageScore,
    required this.ratingsCount,
    required this.commentsCount,
    required this.createdAt,
    this.description,
  });

  factory QotaUserItem.fromMap(Map<String, dynamic> map) => QotaUserItem(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        imageUrl: map['image_url'] as String,
        ownerName: map['owner_name'] as String? ?? '',
        averageScore: (map['average_score'] as num?)?.toDouble() ?? 0,
        ratingsCount: (map['ratings_count'] as num?)?.toInt() ?? 0,
        commentsCount: (map['comments_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
