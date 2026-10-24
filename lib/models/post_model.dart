class PostModel {
  final String postId;
  final String userId;
  final String username;
  final String profileImage;
  final String mediaUrl;
  final String mediaType;
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final String caption;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final bool isReposted;
  final bool isVerified;
  final String? repostNote;
  final String? repostUserAvatar;
  final String? repostUsername;
  final DateTime timestamp;
  final String? location;

  PostModel({
    required this.postId,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.mediaUrl,
    required this.mediaType,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    this.repostsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    this.isReposted = false,
    this.isVerified = false,
    this.repostNote,
    this.repostUserAvatar,
    this.repostUsername,
    required this.timestamp,
    this.location,
  });

  bool get isCarousel => mediaUrls.length > 1;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final rawUser =
        json['user'] ??
        json['userId'] ??
        json['user_id'] ??
        json['author'] ??
        json['userid'];
    String extractedUserId = '';
    String extractedUsername =
        json['username'] ?? json['user_name'] ?? json['name'] ?? '';
    String extractedProfileImage =
        json['profileImage'] ??
        json['profile_image'] ??
        json['profileimage'] ??
        '';

    bool extractedIsVerified =
        json['isVerified'] == 1 ||
        json['isVerified'] == true ||
        json['is_verified'] == 1 ||
        json['is_verified'] == true ||
        json['verified'] == true;

    if (rawUser is Map) {
      extractedUserId =
          (rawUser['uid'] ??
                  rawUser['id'] ??
                  rawUser['_id'] ??
                  rawUser['userId'] ??
                  rawUser['user_id'] ??
                  '')
              .toString();
      if (extractedUsername.isEmpty) {
        extractedUsername =
            (rawUser['username'] ??
                    rawUser['user_name'] ??
                    rawUser['full_name'] ??
                    rawUser['name'] ??
                    '')
                .toString();
      }
      if (extractedProfileImage.isEmpty) {
        extractedProfileImage =
            (rawUser['profileImage'] ??
                    rawUser['profile_image'] ??
                    rawUser['profileimage'] ??
                    rawUser['image'] ??
                    '')
                .toString();
      }
      if (!extractedIsVerified) {
        extractedIsVerified =
            rawUser['isVerified'] == 1 ||
            rawUser['isVerified'] == true ||
            rawUser['is_verified'] == 1 ||
            rawUser['is_verified'] == true ||
            rawUser['verified'] == true;
      }
    } else if (rawUser != null && rawUser.toString().isNotEmpty) {
      extractedUserId = rawUser.toString();
    }

    if (extractedUserId.isEmpty) {
      extractedUserId =
          (json['userId'] ??
                  json['user_id'] ??
                  json['userid'] ??
                  json['_id'] ??
                  json['id'] ??
                  '')
              .toString();
    }
    if (extractedUsername.isEmpty) extractedUsername = 'Anonymous';

    final singleUrl = (json['mediaUrl'] ??
            json['media_url'] ??
            json['url'] ??
            json['media'] ??
            '')
        .toString();
    final singleType = (json['mediaType'] ?? json['media_type'] ?? 'image').toString();

    List<String> parsedUrls = [];
    final rawUrls = json['mediaUrls'] ?? json['media_urls'] ?? json['images'] ?? json['carousel'];
    if (rawUrls is List && rawUrls.isNotEmpty) {
      parsedUrls = rawUrls.map((u) {
        if (u is Map) {
          return (u['url'] ?? u['mediaUrl'] ?? u['media_url'] ?? '').toString();
        }
        return u.toString();
      }).where((u) => u.isNotEmpty).toList();
    }

    if (parsedUrls.isEmpty && singleUrl.isNotEmpty) {
      parsedUrls = [singleUrl];
    }

    List<String> parsedTypes = [];
    final rawTypes = json['mediaTypes'] ?? json['media_types'];
    if (rawTypes is List && rawTypes.isNotEmpty) {
      parsedTypes = rawTypes.map((t) => t.toString()).toList();
    } else {
      parsedTypes = List.filled(parsedUrls.length, singleType);
    }

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
      mediaUrl: singleUrl.isNotEmpty ? singleUrl : (parsedUrls.isNotEmpty ? parsedUrls.first : ''),
      mediaType: singleType,
      mediaUrls: parsedUrls,
      mediaTypes: parsedTypes,
      caption: json['caption'] ?? '',
      likesCount: _toInt(
        json['likesCount'] ?? json['likes_count'] ?? json['likes'],
      ),
      commentsCount: _toInt(
        json['commentsCount'] ?? json['comments_count'] ?? json['comments'],
      ),
      repostsCount: _toInt(
        json['repostsCount'] ?? json['reposts_count'] ?? json['reposts'],
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
      isReposted:
          json['isReposted'] == 1 ||
          json['isReposted'] == true ||
          json['is_reposted'] == true ||
          json['reposted'] == true,
      isVerified: extractedIsVerified,
      repostNote: (json['repostNote'] ?? json['repost_note'] ?? json['note'])
          ?.toString(),
      repostUserAvatar:
          (json['repostUserAvatar'] ??
                  json['repost_user_avatar'] ??
                  json['repostProfileImage'])
              ?.toString(),
      repostUsername: (json['repostUsername'] ?? json['repost_username'])
          ?.toString(),
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
    if (value is List) return value.length;
    if (value is double) return value.toInt();
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
    List<String>? mediaUrls,
    List<String>? mediaTypes,
    String? caption,
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
    bool? isReposted,
    bool? isVerified,
    String? repostNote,
    String? repostUserAvatar,
    String? repostUsername,
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
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      isReposted: isReposted ?? this.isReposted,
      isVerified: isVerified ?? this.isVerified,
      repostNote: repostNote ?? this.repostNote,
      repostUserAvatar: repostUserAvatar ?? this.repostUserAvatar,
      repostUsername: repostUsername ?? this.repostUsername,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
    );
  }
}
