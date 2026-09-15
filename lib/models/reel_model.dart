class ReelModel {
  final String id;
  final String userId;
  final String videoUrl;
  final String caption;
  final String songId;
  final List<String> likes;
  final String creatorName;
  final String thumbnail;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;

  ReelModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.caption,
    required this.songId,
    required this.likes,
    this.creatorName = '',
    this.thumbnail = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    print("DEBUG Reel JSON: $json");
    return ReelModel(
      id: (json['id'] ?? json['reelId'] ?? json['reel_id'] ?? '').toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      videoUrl:
          json['videoUrl'] ??
          json['video_url'] ??
          json['url'] ??
          json['media'] ??
          '',
      caption: json['caption'] ?? '',
      songId: json['songId'] ?? json['song_name'] ?? '',
      likes: const [],
      creatorName:
          json['username'] ??
          json['creator_name'] ??
          json['full_name'] ??
          'Anonymous',
      thumbnail:
          json['thumbnail'] ??
          json['profileImage'] ??
          json['profile_image'] ??
          '',
      likesCount: _toInt(json['likesCount'] ?? json['likes_count'] ?? json['likes']),
      commentsCount: _toInt(json['commentsCount'] ?? json['comments_count'] ?? json['comments']),
      isLiked:
          json['isLiked'] == 1 ||
          json['isLiked'] == true ||
          json['is_liked'] == true ||
          json['liked'] == true,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  ReelModel copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? caption,
    String? songId,
    List<String>? likes,
    String? creatorName,
    String? thumbnail,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return ReelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      songId: songId ?? this.songId,
      likes: likes ?? this.likes,
      creatorName: creatorName ?? this.creatorName,
      thumbnail: thumbnail ?? this.thumbnail,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
