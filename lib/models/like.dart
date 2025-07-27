class Like {
  final int? id;
  final int userId;
  final int targetId;
  final String targetType; // 'post' or 'comment'
  final DateTime createdAt;

  Like({
    this.id,
    required this.userId,
    required this.targetId,
    required this.targetType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'target_id': targetId,
      'target_type': targetType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Like.fromMap(Map<String, dynamic> map) {
    return Like(
      id: map['id'],
      userId: map['user_id'],
      targetId: map['target_id'],
      targetType: map['target_type'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'target_id': targetId,
      'target_type': targetType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
