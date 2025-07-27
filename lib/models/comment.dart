class Comment {
  final int? id;
  final int postId;
  final int userId;
  final String content;
  final int? parentCommentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final bool isEdited;

  Comment({
    this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.parentCommentId,
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.isEdited = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'like_count': likeCount,
      'is_edited': isEdited ? 1 : 0,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      postId: map['post_id'],
      userId: map['user_id'],
      content: map['content'],
      parentCommentId: map['parent_comment_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      likeCount: map['like_count'] ?? 0,
      isEdited: map['is_edited'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'parent_comment_id': parentCommentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'like_count': likeCount,
      'is_edited': isEdited,
    };
  }
}
