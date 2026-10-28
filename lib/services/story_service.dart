import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:momento/models/story_model.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/utils/api_constants.dart';

class StoryService {
  final ApiService _apiService;

  StoryService(this._apiService);

  Future<List<StoryModel>> fetchStories() async {
    try {
      final response = await _apiService.get(ApiConstants.stories);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List storyJson = [];
        if (decoded is List) {
          storyJson = decoded;
        } else if (decoded is Map) {
          storyJson =
              decoded['data'] ?? decoded['stories'] ?? decoded['results'] ?? [];
        }

        final List<StoryModel> parsedStories = [];
        final Set<String> seenStoryIds = {};

        for (final json in storyJson) {
          if (json is Map<String, dynamic>) {
            final story = StoryModel.fromJson(json);
            if (story.storyId.isNotEmpty &&
                !seenStoryIds.contains(story.storyId)) {
              seenStoryIds.add(story.storyId);
              parsedStories.add(story);
            }
          }
        }
        return parsedStories;
      }
      return [];
    } catch (e) {
      print("Error fetching stories: $e");
      return [];
    }
  }

  Future<bool> createStory(
    String filePath,
    String mediaType, {
    String? caption,
    String? songId,
    String? audioUrl,
    String? songTitle,
    double? clipStart,
  }) async {
    final user = await _apiService.getUser();
    final userId = (user?['id'] ?? user?['uid'] ?? user?['userId'] ?? '')
        .toString();
    final username = (user?['username'] ?? user?['name'] ?? 'User').toString();

    final songData = <String, String>{
      if (songId != null && songId.isNotEmpty) 'songId': songId,
      if (songId != null && songId.isNotEmpty) 'song_id': songId,
      if (audioUrl != null && audioUrl.isNotEmpty) 'audioUrl': audioUrl,
      if (audioUrl != null && audioUrl.isNotEmpty) 'audio_url': audioUrl,
      if (songTitle != null && songTitle.isNotEmpty) 'songTitle': songTitle,
      if (songTitle != null && songTitle.isNotEmpty) 'song_title': songTitle,
      if (clipStart != null) 'clipStart': clipStart.toString(),
      if (clipStart != null) 'clip_start': clipStart.toString(),
      if (clipStart != null) 'start_time': clipStart.toString(),
    };

    // 0. If filePath is ALREADY a Network URL (e.g. Cloudinary link from post/reel)
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      try {
        final jsonBody = <String, dynamic>{
          'mediaUrl': filePath,
          'media_url': filePath,
          'url': filePath,
          'media': filePath,
          'image': filePath,
          'story': filePath,
          'mediaType': mediaType,
          'media_type': mediaType,
          'type': mediaType,
          'caption': (caption == null || caption.isEmpty)
              ? 'New Story'
              : caption,
          if (userId.isNotEmpty) 'userId': userId,
          if (userId.isNotEmpty) 'user_id': userId,
          if (userId.isNotEmpty) 'user': userId,
          if (username.isNotEmpty) 'username': username,
          ...songData,
        };

        print(
          "StoryService: Creating story directly from Network URL -> $filePath",
        );
        final response = await _apiService.post(ApiConstants.stories, jsonBody);
        print(
          "StoryService: Direct Network Story response status: ${response.statusCode}",
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        print("StoryService: Direct Network Story error: $e");
      }
    }

    // 1. Try Base64 JSON (For local files)
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final ext = filePath.toLowerCase().endsWith('.png')
            ? 'png'
            : (mediaType == 'video' ? 'mp4' : 'jpeg');
        final prefix = mediaType == 'video' ? 'video' : 'image';
        final base64Image = 'data:$prefix/$ext;base64,${base64Encode(bytes)}';

        final jsonBody = <String, dynamic>{
          'mediaUrl': base64Image,
          'media_url': base64Image,
          'url': base64Image,
          'media': base64Image,
          'image': base64Image,
          'story': base64Image,
          'file': base64Image,
          'mediaType': mediaType,
          'media_type': mediaType,
          'type': mediaType,
          'caption': (caption == null || caption.isEmpty)
              ? 'New Story'
              : caption,
          if (userId.isNotEmpty) 'userId': userId,
          if (userId.isNotEmpty) 'user_id': userId,
          if (userId.isNotEmpty) 'user': userId,
          if (username.isNotEmpty) 'username': username,
          ...songData,
        };

        final response = await _apiService.post(ApiConstants.stories, jsonBody);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        } else {
          if (kDebugMode) {
            print(
              "Base64 Story failed: ${response.statusCode} - ${response.body}",
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Base64 Story error: $e");
      }
    }

    // 2. Fallback to Multipart
    final fields = <String, String>{
      'caption': (caption == null || caption.isEmpty) ? 'New Story' : caption,
      'mediaType': mediaType,
      'media_type': mediaType,
      'type': mediaType,
      if (userId.isNotEmpty) 'userId': userId,
      if (userId.isNotEmpty) 'user_id': userId,
      if (userId.isNotEmpty) 'user': userId,
      if (userId.isNotEmpty) 'author': userId,
      if (username.isNotEmpty) 'username': username,
      ...songData,
    };

    final fileKeysToTry = ['media', 'file', 'image', 'story'];

    for (final key in fileKeysToTry) {
      try {
        final response = await _apiService.postMultipart(
          ApiConstants.stories,
          fields,
          key,
          filePath,
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  Future<bool> markAsViewed(String storyId) async {
    final response = await _apiService.put(
      "${ApiConstants.stories}/$storyId/view",
      {},
    );
    return response.statusCode == 200;
  }

  Future<bool> toggleLikeStory(String storyId) async {
    try {
      final response = await _apiService.post(
        "${ApiConstants.stories}/$storyId/like",
        {},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        print("Error toggling story like: $e");
      }
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchStoryViewers(String storyId) async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.stories}/$storyId/viewers",
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List list =
            decoded['data'] ?? decoded['viewers'] ?? decoded['views'] ?? [];
        return list.map((v) {
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
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching story viewers: $e");
      }
    }
    return [];
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      final response = await _apiService.delete(
        "${ApiConstants.stories}/$storyId",
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting story: $e");
      }
      return false;
    }
  }
}
