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
    return StoryModel(
      storyId: (json['id'] ?? json['storyId'] ?? json['story_id'] ?? '')
          .toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      username: json['username'] ?? 'Anonymous',
      profileImage: json['profileImage'] ?? json['profile_image'] ?? '',
      mediaUrl: json['mediaUrl'] ?? json['media_url'] ?? '',
      mediaType: json['mediaType'] ?? json['media_type'] ?? 'image',
      timestamp: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'])
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
