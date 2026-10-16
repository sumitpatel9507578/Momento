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
    if (kDebugMode) {
      print("DEBUG Story JSON: $json");
    }
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
      timestamp: DateTime.parse(
        (json['createdAt'] ??
                json['created_at'] ??
                DateTime.now().toIso8601String())
            .toString(),
      ).toLocal(),
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
