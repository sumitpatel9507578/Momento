class NotificationModel {
  final String id;
  final String userId;
  final String actorId;
  final String actorName;
  final String actorImage;
  final String type; // 'like', 'comment', 'follow', 'message'
  final String? referenceId; // postId, reelId etc
  final String message;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.actorName,
    required this.actorImage,
    required this.type,
    this.referenceId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      actorId: (json['actor_id'] ?? '').toString(),
      actorName: json['actorName'] ?? 'Someone',
      actorImage: json['actorImage'] ?? '',
      type: json['type'] ?? '',
      referenceId: (json['reference_id'] ?? '').toString(),
      message: json['message'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'actor_id': actorId,
      'type': type,
      'reference_id': referenceId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
