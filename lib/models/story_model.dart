class StoryModel {
  final String storyId;
  final String userId;
  final String username;
  final String profileImage;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime timestamp;
  final bool viewed;

  StoryModel({
    required this.storyId,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.mediaUrl,
    required this.mediaType,
    required this.timestamp,
    this.viewed = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    print("DEBUG Story JSON: $json");
    final user = json['user'] is Map ? json['user'] : null;
    return StoryModel(
      storyId: (json['id'] ?? json['storyId'] ?? json['story_id'] ?? '')
          .toString(),
      userId:
          (json['userId'] ??
                  json['user_id'] ??
                  user?['id'] ??
                  user?['uid'] ??
                  '')
              .toString(),
      username:
          json['username'] ?? user?['username'] ?? user?['name'] ?? 'User',
      profileImage:
          json['profileImage'] ??
          json['profile_image'] ??
          user?['profileImage'] ??
          user?['profile_image'] ??
          '',
      mediaUrl:
          json['mediaUrl'] ??
          json['media_url'] ??
          json['url'] ??
          json['image'] ??
          '',
      mediaType:
          json['mediaType'] ?? json['media_type'] ?? json['type'] ?? 'image',
      timestamp: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.tryParse(
                  (json['createdAt'] ?? json['created_at']).toString(),
                ) ??
                DateTime.now()
          : DateTime.now(),
      viewed: json['viewed'] == 1 || json['viewed'] == true,
    );
  }

  StoryModel copyWith({
    String? storyId,
    String? userId,
    String? username,
    String? profileImage,
    String? mediaUrl,
    String? mediaType,
    DateTime? timestamp,
    bool? viewed,
  }) {
    return StoryModel(
      storyId: storyId ?? this.storyId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      timestamp: timestamp ?? this.timestamp,
      viewed: viewed ?? this.viewed,
    );
  }
}
