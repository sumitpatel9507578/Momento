import 'package:flutter/foundation.dart';

class StoryModel {
  final String storyId;
  final String userId;
  final String username;
  final String profileImage;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime timestamp;
  final bool viewed;
  final bool isLiked;
  final int likesCount;
  final int viewsCount;
  final List<Map<String, dynamic>> viewers;
  final String audioUrl;
  final String songTitle;

  StoryModel({
    required this.storyId,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.mediaUrl,
    required this.mediaType,
    required this.timestamp,
    this.viewed = false,
    this.isLiked = false,
    this.likesCount = 0,
    this.viewsCount = 0,
    this.viewers = const [],
    this.audioUrl = '',
    this.songTitle = '',
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("DEBUG Story JSON: $json");
    }
    final user = json['user'] is Map ? json['user'] : null;

    final rawViewers =
        json['viewers'] ?? json['views'] ?? json['viewedBy'] ?? [];
    List<Map<String, dynamic>> parsedViewers = [];
    if (rawViewers is List) {
      parsedViewers = rawViewers
          .map((v) {
            if (v is Map) {
              final u = v['user'] is Map ? v['user'] : v;
              return {
                'id': (u['id'] ?? u['uid'] ?? u['_id'] ?? '').toString(),
                'name': (u['name'] ?? u['full_name'] ?? u['username'] ?? 'User')
                    .toString(),
                'username': (u['username'] ?? '').toString(),
                'profileImage': (u['profileImage'] ?? u['profile_image'] ?? '')
                    .toString(),
                'viewedAt':
                    (v['createdAt'] ??
                            v['viewedAt'] ??
                            DateTime.now().toIso8601String())
                        .toString(),
                'liked': v['liked'] == true || v['isLiked'] == true,
              };
            }
            return <String, dynamic>{};
          })
          .where((v) => v.isNotEmpty)
          .toList();
    }

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
      timestamp: DateTime.parse(
        (json['createdAt'] ??
                json['created_at'] ??
                DateTime.now().toIso8601String())
            .toString(),
      ).toLocal(),
      viewed: json['viewed'] == 1 || json['viewed'] == true,
      isLiked:
          json['isLiked'] == true ||
          json['is_liked'] == true ||
          json['liked'] == true,
      likesCount:
          json['likesCount'] ??
          json['likes_count'] ??
          (json['likes'] is List ? (json['likes'] as List).length : 0),
      viewsCount:
          json['viewsCount'] ??
          json['views_count'] ??
          (json['views'] is List
              ? (json['views'] as List).length
              : parsedViewers.length),
      viewers: parsedViewers,
      audioUrl: (json['audioUrl'] ?? json['audio_url'] ?? json['audio'] ?? '')
          .toString(),
      songTitle:
          (json['songTitle'] ??
                  json['song_title'] ??
                  json['song'] ??
                  (json['caption']?.toString().startsWith('🎵 ') == true
                      ? json['caption'].toString()
                      : ''))
              .toString(),
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
    bool? isLiked,
    int? likesCount,
    int? viewsCount,
    List<Map<String, dynamic>>? viewers,
    String? audioUrl,
    String? songTitle,
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
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      viewers: viewers ?? this.viewers,
      audioUrl: audioUrl ?? this.audioUrl,
      songTitle: songTitle ?? this.songTitle,
    );
  }
}

class UserStories {
  final String userId;
  final String username;
  final String profileImage;
  final List<StoryModel> stories;

  UserStories({
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.stories,
  });

  bool get allViewed => stories.every((s) => s.viewed);

  int get firstUnviewedIndex {
    final idx = stories.indexWhere((s) => !s.viewed);
    return idx != -1 ? idx : 0;
  }

  DateTime get latest {
    if (stories.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return stories.fold(
      stories.first.timestamp,
      (prev, s) => s.timestamp.isAfter(prev) ? s.timestamp : prev,
    );
  }
}
