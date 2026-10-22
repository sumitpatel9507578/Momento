class CommentModel {
  final String id;
  final String postId;
  final String? parentId;
  final String userId;
  final String username;
  final String profileImage;
  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final DateTime createdAt;
  final int likeCount;
  final bool isLikedByMe;
  final bool isLikedByAuthor;
  final bool isPinned;
  final bool isVerified;
  final int replyCount;
  final List<String> mentions;
  final bool isAuthor;
  final bool isPending;
  final String? sendError;
  final bool isEdited;

  CommentModel({
    required this.id,
    required this.postId,
    this.parentId,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.isLikedByAuthor = false,
    this.isPinned = false,
    this.isVerified = false,
    this.replyCount = 0,
    this.mentions = const [],
    this.isAuthor = false,
    this.isPending = false,
    this.sendError,
    this.isEdited = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final dateStr = json['createdAt'] ?? json['created_at'];
      parsedDate = dateStr != null
          ? DateTime.parse(dateStr.toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawUser = json['user'];
    bool extractedIsVerified =
        json['isVerified'] == true ||
        json['is_verified'] == true ||
        json['verified'] == true;

    if (!extractedIsVerified && rawUser is Map) {
      extractedIsVerified =
          rawUser['isVerified'] == true ||
          rawUser['is_verified'] == true ||
          rawUser['verified'] == true;
    }

    return CommentModel(
      id: (json['id'] ?? json['_id'] ?? json['commentId'] ?? '').toString(),
      postId:
          (json['postId'] ??
                  json['post_id'] ??
                  json['reelId'] ??
                  json['reel_id'] ??
                  '')
              .toString(),
      parentId:
          (json['parentId'] ?? json['parent_id'] ?? json['parentCommentId'])
              ?.toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      username: (json['username'] ?? json['user']?['username'] ?? 'User')
          .toString(),
      profileImage:
          (json['profileImage'] ??
                  json['profile_image'] ??
                  json['user']?['profileImage'] ??
                  '')
              .toString(),
      text: (json['text'] ?? json['comment'] ?? '').toString(),
      mediaUrl: (json['mediaUrl'] ?? json['media_url'])?.toString(),
      mediaType: (json['mediaType'] ?? json['media_type'])?.toString(),
      createdAt: parsedDate,
      likeCount:
          int.tryParse(
            (json['likeCount'] ??
                    json['likesCount'] ??
                    json['likes_count'] ??
                    json['likes'] ??
                    0)
                .toString(),
          ) ??
          0,
      isLikedByMe:
          json['isLikedByMe'] == true ||
          json['is_liked_by_me'] == true ||
          json['isLiked'] == true ||
          json['liked'] == true,
      isLikedByAuthor:
          json['isLikedByAuthor'] == true || json['is_liked_by_author'] == true,
      isPinned: json['isPinned'] == true || json['is_pinned'] == true,
      isVerified: extractedIsVerified,
      replyCount:
          int.tryParse(
            (json['replyCount'] ?? json['reply_count'] ?? 0).toString(),
          ) ??
          0,
      mentions: json['mentions'] is List
          ? List<String>.from(json['mentions'])
          : [],
      isAuthor: json['isAuthor'] == true || json['is_author'] == true,
      isPending: json['isPending'] == true,
      sendError: json['sendError']?.toString(),
      isEdited: json['isEdited'] == true || json['is_edited'] == true,
    );
  }

  CommentModel copyWith({
    String? id,
    String? postId,
    String? parentId,
    String? userId,
    String? username,
    String? profileImage,
    String? text,
    String? mediaUrl,
    String? mediaType,
    DateTime? createdAt,
    int? likeCount,
    bool? isLikedByMe,
    bool? isLikedByAuthor,
    bool? isPinned,
    bool? isVerified,
    int? replyCount,
    List<String>? mentions,
    bool? isAuthor,
    bool? isPending,
    String? sendError,
    bool? isEdited,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isLikedByAuthor: isLikedByAuthor ?? this.isLikedByAuthor,
      isPinned: isPinned ?? this.isPinned,
      isVerified: isVerified ?? this.isVerified,
      replyCount: replyCount ?? this.replyCount,
      mentions: mentions ?? this.mentions,
      isAuthor: isAuthor ?? this.isAuthor,
      isPending: isPending ?? this.isPending,
      sendError: sendError ?? this.sendError,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
