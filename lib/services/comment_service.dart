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
    final endpointsToTry = isReel
        ? [
            "${ApiConstants.reels}/$id/comments",
            "${ApiConstants.baseUrl}/comments/reel/$id",
            "${ApiConstants.baseUrl}/comments?reelId=$id",
            "${ApiConstants.baseUrl}/comments?reel_id=$id",
            "${ApiConstants.reels}/comments/$id",
          ]
        : [
            "${ApiConstants.posts}/$id/comments",
            "${ApiConstants.baseUrl}/comments/post/$id",
            "${ApiConstants.baseUrl}/comments?postId=$id",
            "${ApiConstants.posts}/comments/$id",
          ];

    for (final endpoint in endpointsToTry) {
      try {
        final response = await _apiService.get(endpoint);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List commentsJson = data['data'] ?? data['comments'] ?? [];
          return List<Map<String, dynamic>>.from(commentsJson);
        }
      } catch (_) {}
    }
    return [];
  }

  Future<bool> addComment(
    String id,
    String comment, {
    bool isReel = false,
    String? parentId,
  }) async {
    try {
      final endpoint = isReel ? ApiConstants.reels : ApiConstants.posts;
      final body = <String, dynamic>{
        'comment': comment,
        'text': comment,
        'parentId': parentId,
      };
      var response = await _apiService.post("$endpoint/$id/comments", body);

      if (response.statusCode == 404 && isReel) {
        response = await _apiService.post(
          "${ApiConstants.baseUrl}/comments/reel/$id",
          body,
        );
      }

      if (response.statusCode == 404 && isReel) {
        response = await _apiService.post("${ApiConstants.baseUrl}/comments", {
          'reelId': id,
          'comment': comment,
          'text': comment,
          'parentId': parentId,
        });
      }

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("AddComment Error: $e");
      return false;
    }
  }

  Future<bool> likeComment(
    String commentId, {
    String? targetId,
    bool isReel = false,
  }) async {
    final endpointsToTry = [
      "${ApiConstants.baseUrl}/comments/$commentId/like",
      "${ApiConstants.posts}/comments/$commentId/like",
      if (targetId != null)
        "${ApiConstants.posts}/$targetId/comments/$commentId/like",
      if (targetId != null && isReel)
        "${ApiConstants.reels}/$targetId/comments/$commentId/like",
      "${ApiConstants.baseUrl}/posts/comments/$commentId/like",
    ];

    for (final url in endpointsToTry) {
      try {
        final response = await _apiService.post(url, {});
        if (response.statusCode == 200 || response.statusCode == 201) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<bool> editComment(
    String commentId,
    String text, {
    String? targetId,
    bool isReel = false,
  }) async {
    final endpointsToTry = [
      "${ApiConstants.baseUrl}/comments/$commentId",
      "${ApiConstants.posts}/comments/$commentId",
      if (targetId != null)
        "${ApiConstants.posts}/$targetId/comments/$commentId",
      if (targetId != null && isReel)
        "${ApiConstants.reels}/$targetId/comments/$commentId",
      "${ApiConstants.baseUrl}/posts/comments/$commentId",
    ];

    for (final url in endpointsToTry) {
      try {
        final response = await _apiService.put(url, {
          'comment': text,
          'text': text,
        });
        if (response.statusCode == 200 || response.statusCode == 201) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<bool> deleteComment(
    String commentId, {
    String? targetId,
    bool isReel = false,
  }) async {
    final endpointsToTry = [
      "${ApiConstants.baseUrl}/comments/$commentId",
      "${ApiConstants.posts}/comments/$commentId",
      if (targetId != null)
        "${ApiConstants.posts}/$targetId/comments/$commentId",
      if (targetId != null && isReel)
        "${ApiConstants.reels}/$targetId/comments/$commentId",
      "${ApiConstants.baseUrl}/posts/comments/$commentId",
    ];

    for (final url in endpointsToTry) {
      try {
        final response = await _apiService.delete(url);
        if (response.statusCode == 200 ||
            response.statusCode == 200 ||
            response.statusCode == 204) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }
}
