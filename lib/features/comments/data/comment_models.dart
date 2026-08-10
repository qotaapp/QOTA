class QotaComment {
  final String id;
  final String entityId;
  final String userId;
  final String authorName; // §31 : nom de l'auteur visible au public
  final String text;
  final String? imageUrl;
  final int likesCount;
  final bool likedByMe;
  final DateTime createdAt;

  QotaComment({
    required this.id,
    required this.entityId,
    required this.userId,
    required this.authorName,
    required this.text,
    required this.likesCount,
    required this.likedByMe,
    required this.createdAt,
    this.imageUrl,
  });

  factory QotaComment.fromMap(Map<String, dynamic> map) => QotaComment(
        id: map['id'] as String,
        entityId: map['entity_id'] as String,
        userId: map['user_id'] as String,
        authorName: map['author_name'] as String? ?? '',
        text: map['text'] as String,
        imageUrl: map['image_url'] as String?,
        likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
        likedByMe: map['liked_by_me'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// §33 : une réponse ne contient JAMAIS d'image.
class QotaCommentReply {
  final String id;
  final String commentId;
  final String userId;
  final String authorName;
  final String text;
  final int likesCount;
  final bool likedByMe;
  final DateTime createdAt;

  QotaCommentReply({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.authorName,
    required this.text,
    required this.likesCount,
    required this.likedByMe,
    required this.createdAt,
  });

  factory QotaCommentReply.fromMap(Map<String, dynamic> map) => QotaCommentReply(
        id: map['id'] as String,
        commentId: map['comment_id'] as String,
        userId: map['user_id'] as String,
        authorName: map['author_name'] as String? ?? '',
        text: map['text'] as String,
        likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
        likedByMe: map['liked_by_me'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
