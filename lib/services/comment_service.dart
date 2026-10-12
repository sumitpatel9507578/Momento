import 'dart:convert';

import 'package:get/get.dart';

import '../utils/api_constants.dart';
import 'api_service.dart';

class CommentService extends GetxService {
  final ApiService _apiService;

  CommentService(this._apiService);

  Future<List<Map<String, dynamic>>> fetchComments(
    String id, {
    bool isReel = false,
  }) async {
    try {
      final endpoint = isReel ? ApiConstants.reels : ApiConstants.posts;
      var response = await _apiService.get("$endpoint/$id/comments");

      if (response.statusCode == 404 && isReel) {
        response = await _apiService.get(
          "${ApiConstants.baseUrl}/comments/reel/$id",
        );
      }
      if (response.statusCode == 404 && isReel) {
        response = await _apiService.get("${ApiConstants.reels}/comments/$id");
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List commentsJson = data['data'] ?? data['comments'] ?? [];
        return List<Map<String, dynamic>>.from(commentsJson);
      }
      return [];
    } catch (e) {
      print("CommentService Error: $e");
      return [];
    }
  }

  Future<bool> addComment(
    String id,
    String comment, {
    bool isReel = false,
  }) async {
    try {
      final endpoint = isReel ? ApiConstants.reels : ApiConstants.posts;
      print("CommentService: Posting to $endpoint/$id/comments");
      var response = await _apiService.post("$endpoint/$id/comments", {
        'comment': comment,
        'text': comment,
      });

      if (response.statusCode == 404 && isReel) {
        response = await _apiService.post(
          "${ApiConstants.baseUrl}/comments/reel/$id",
          {'comment': comment, 'text': comment},
        );
      }

      if (response.statusCode == 404 && isReel) {
        response = await _apiService.post("${ApiConstants.baseUrl}/comments", {
          'reelId': id,
          'comment': comment,
          'text': comment,
        });
      }

      if (response.statusCode >= 400) {
        print("CommentService Error Body: ${response.body}");
      }

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("AddComment Error: $e");
      return false;
    }
  }
}
