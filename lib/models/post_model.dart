class PostModel {
  final String postId;
  final String userId;
  final String username;
  final String profileImage;
  final String mediaUrl;
  final String mediaType;
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

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // CRITICAL DEBUG: Print the JSON to see why images are broken
    print("DEBUG Post JSON: $json");

    final rawUser = json['user'] ?? json['userId'] ?? json['user_id'] ?? json['author'] ?? json['userid'];
    String extractedUserId = '';
    String extractedUsername = json['username'] ?? json['user_name'] ?? json['name'] ?? '';
    String extractedProfileImage = json['profileImage'] ?? json['profile_image'] ?? json['profileimage'] ?? '';

    if (rawUser is Map) {
      extractedUserId = (rawUser['uid'] ?? rawUser['id'] ?? rawUser['_id'] ?? rawUser['userId'] ?? rawUser['user_id'] ?? '').toString();
      if (extractedUsername.isEmpty) {
        extractedUsername = (rawUser['username'] ?? rawUser['user_name'] ?? rawUser['full_name'] ?? rawUser['name'] ?? '').toString();
      }
      if (extractedProfileImage.isEmpty) {
        extractedProfileImage = (rawUser['profileImage'] ?? rawUser['profile_image'] ?? rawUser['profileimage'] ?? rawUser['image'] ?? '').toString();
      }
    } else if (rawUser != null && rawUser.toString().isNotEmpty) {
      extractedUserId = rawUser.toString();
    }

    if (extractedUserId.isEmpty) {
      extractedUserId = (json['userId'] ?? json['user_id'] ?? json['userid'] ?? json['_id'] ?? json['id'] ?? '').toString();
    }
    if (extractedUsername.isEmpty) extractedUsername = 'Anonymous';

    return PostModel(
      postId:
          (json['postId'] ??
                  json['post_id'] ??
                  json['postid'] ??
                  json['_id'] ??
                  json['id'] ??
                  '')
              .toString(),
      userId: extractedUserId,
      username: extractedUsername,
      profileImage: extractedProfileImage,
      mediaUrl:
          json['mediaUrl'] ??
          json['media_url'] ??
          json['url'] ??
          json['media'] ??
          '',
      mediaType: json['mediaType'] ?? json['media_type'] ?? 'image',
      caption: json['caption'] ?? '',
      likesCount: _toInt(
        json['likesCount'] ?? json['likes_count'] ?? json['likes'],
      ),
      commentsCount: _toInt(
        json['commentsCount'] ?? json['comments_count'] ?? json['comments'],
      ),
      isLiked:
          json['isLiked'] == 1 ||
          json['isLiked'] == true ||
          json['is_liked'] == true ||
          json['liked'] == true,
      isSaved:
          json['isSaved'] == 1 ||
          json['isSaved'] == true ||
          json['is_saved'] == true ||
          json['saved'] == true,
      isFollowing:
          json['isFollowing'] == 1 ||
          json['isFollowing'] == true ||
          json['is_following'] == true ||
          json['following'] == true,
      timestamp: _parseDate(
        json['createdAt'] ??
            json['created_at'] ??
            json['timestamp'] ??
            json['date'],
      ),
      location: json['location'],
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    try {
      if (date is String) return DateTime.parse(date);
      return DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

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
