class QotaRating {
  final String id;
  final String entityId;
  final String userId;
  final int score;
  final String? commentText;
  final String? imageUrl;

  QotaRating({
    required this.id,
    required this.entityId,
    required this.userId,
    required this.score,
    this.commentText,
    this.imageUrl,
  });

  factory QotaRating.fromMap(Map<String, dynamic> map) => QotaRating(
        id: map['id'] as String,
        entityId: map['entity_id'] as String,
        userId: map['user_id'] as String,
        score: map['score'] as int,
        commentText: map['comment_text'] as String?,
        imageUrl: map['image_url'] as String?,
      );
}
