import 'dart:convert';
import 'dart:io';

import '../models/story_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

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
        return storyJson.map((json) => StoryModel.fromJson(json)).toList();
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
  }) async {
    final user = await _apiService.getUser();
    final userId = (user?['id'] ?? user?['uid'] ?? user?['userId'] ?? '')
        .toString();
    final username = (user?['username'] ?? user?['name'] ?? 'User').toString();

    // 1. Try Base64 JSON FIRST (Since multipart seems misconfigured/crashing on Render backend)
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
        };

        final response = await _apiService.post(ApiConstants.stories, jsonBody);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        } else {
          print(
            "Base64 Story failed: ${response.statusCode} - ${response.body}",
          );
        }
      }
    } catch (e) {
      print("Base64 Story error: $e");
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
}
