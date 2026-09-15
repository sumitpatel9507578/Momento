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

  Future<bool> createReel(
    String caption,
    String filePath, {
    String? songId,
  }) async {
    final response = await _apiService.postMultipart(
      ApiConstants.reels,
      {
        'caption': caption,
        'mediaType': 'video',
        if (songId != null) 'songId': songId,
      },
      'media', // Unified to 'media' key to match PostService
      filePath,
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> toggleLike(String reelId) async {
    try {
      var response = await _apiService.post(
        ApiConstants.likes,
        {'postId': reelId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) return true;

      response = await _apiService.post(
        ApiConstants.likes,
        {'reelId': reelId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) return true;

      response = await _apiService.post(
        "${ApiConstants.reels}/$reelId/like",
        {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) return true;

      response = await _apiService.post(
        "${ApiConstants.likes}/reel/$reelId",
        {},
      );
      return response.statusCode == 200 || response.statusCode == 201;
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
}
