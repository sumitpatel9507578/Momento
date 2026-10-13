import 'dart:convert';

import '../models/reel_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class ReelService {
  final ApiService _apiService;

  ReelService(this._apiService);

  Future<List<ReelModel>> fetchReels({int page = 1}) async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.reels}?page=$page",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List reelsJson = data['data'] ?? data['reels'] ?? [];
        return reelsJson.map((json) => ReelModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("ReelService Error: $e");
      return [];
    }
  }

  Future<List<ReelModel>> fetchUserReels(String userId) async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.reels}/user/$userId",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List reelsJson = data['data'] ?? data['reels'] ?? [];
        return reelsJson.map((json) => ReelModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("ReelService Error: $e");
      return [];
    }
  }

  Future<ReelModel?> fetchReelById(String reelId) async {
    final response = await _apiService.get("${ApiConstants.reels}/$reelId");
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Failed to load reel (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! Map || data['success'] != true || data['data'] is! Map) {
      throw const FormatException('The reel response was invalid');
    }
    return ReelModel.fromJson(Map<String, dynamic>.from(data['data'] as Map));
  }

  Future<bool> createReel(
    String caption,
    String filePath, {
    String? songId,
  }) async {
    final user = await _apiService.getUser();
    final userId = (user?['id'] ?? user?['uid'] ?? user?['userId'] ?? '')
        .toString();
    final username = (user?['username'] ?? user?['name'] ?? 'User').toString();

    final fields = <String, String>{
      'caption': caption.isEmpty ? 'New Reel' : caption,
      'mediaType': 'video',
      'media_type': 'video',
      if (userId.isNotEmpty) 'userId': userId,
      if (userId.isNotEmpty) 'user_id': userId,
      if (username.isNotEmpty) 'username': username,
      if (songId != null) 'songId': songId,
    };

    // 1. Try Multipart key 'media'
    var response = await _apiService.postMultipart(
      ApiConstants.reels,
      fields,
      'media',
      filePath,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }

    // 2. Try Multipart key 'file'
    response = await _apiService.postMultipart(
      ApiConstants.reels,
      fields,
      'file',
      filePath,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }

    // Base64 logic removed per backend update instruction
    return false;
  }

  Future<bool> toggleLike(String reelId) async {
    try {
      final user = await _apiService.getUser();
      final userId = (user?['id'] ?? user?['uid'] ?? user?['userId'] ?? '')
          .toString();

      final body = <String, dynamic>{
        'reelId': reelId,
        'reel_id': reelId,
        if (userId.isNotEmpty) 'userId': userId,
        if (userId.isNotEmpty) 'user_id': userId,
      };

      bool isSuccess(dynamic response) {
        if (response.statusCode != 200 && response.statusCode != 201)
          return false;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['success'] == false) return false;
        } catch (_) {}
        return true;
      }

      // 1. Try POST /api/likes/reel/{reelId}
      var response = await _apiService.post(
        "${ApiConstants.likes}/reel/$reelId",
        body,
      );
      if (isSuccess(response)) return true;

      // 2. Try POST /api/reels/{reelId}/like
      response = await _apiService.post(
        "${ApiConstants.reels}/$reelId/like",
        body,
      );
      if (isSuccess(response)) return true;

      // 3. Try POST /api/likes with body
      response = await _apiService.post(ApiConstants.likes, body);
      return isSuccess(response);
    } catch (e) {
      print("ReelService toggleLike error: $e");
      return false;
    }
  }

  Future<bool> addComment(String reelId, String comment) async {
    final response = await _apiService.post(
      "${ApiConstants.reels}/$reelId/comments",
      {'comment': comment},
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> deleteReel(String reelId) async {
    try {
      var response = await _apiService.delete("${ApiConstants.reels}/$reelId");
      if (response.statusCode == 200 || response.statusCode == 204) return true;
      response = await _apiService.delete(
        "${ApiConstants.baseUrl}/reels/$reelId",
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("ReelService deleteReel error: $e");
      return false;
    }
  }
}
