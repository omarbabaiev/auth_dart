class Follow {
  final int? id;
  final int followerId;
  final int followingId;
  final DateTime createdAt;

  Follow({
    this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Follow.fromMap(Map<String, dynamic> map) {
    return Follow(
      id: map['id'],
      followerId: map['follower_id'],
      followingId: map['following_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
