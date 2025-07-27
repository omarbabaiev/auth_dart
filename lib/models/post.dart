class Post {
  final int? id;
  final int userId;
  final String content;
  final String? imageUrl;
  final List<String>? hashtags;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isEdited;

  Post({
    this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    this.hashtags,
    this.isPublic = true,
    required this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isEdited = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'hashtags': hashtags?.join(','),
      'is_public': isPublic ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'is_edited': isEdited ? 1 : 0,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      userId: map['user_id'],
      content: map['content'],
      imageUrl: map['image_url'],
      hashtags: map['hashtags']?.split(','),
      isPublic: map['is_public'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      likeCount: map['like_count'] ?? 0,
      commentCount: map['comment_count'] ?? 0,
      shareCount: map['share_count'] ?? 0,
      isEdited: map['is_edited'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'hashtags': hashtags,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'is_edited': isEdited,
    };
  }
}
