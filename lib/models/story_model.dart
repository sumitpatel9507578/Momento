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
