class PostModel {
  final String postId;
  final String userId;
  final String username;
  final String profileImage;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String caption;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final DateTime timestamp;
  final String? location;

  PostModel({
    required this.postId,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.mediaUrl,
    required this.mediaType,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    required this.timestamp,
    this.location,
  });

  PostModel copyWith({
    String? postId,
    String? userId,
    String? username,
    String? profileImage,
    String? mediaUrl,
    String? mediaType,
    String? caption,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
    DateTime? timestamp,
    String? location,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
    );
  }
}
