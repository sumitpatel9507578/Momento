import 'dart:convert';

import '../models/post_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class PostService {
  final ApiService _apiService;

  PostService(this._apiService);

  Future<List<PostModel>> fetchPosts({int page = 1}) async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.posts}?page=$page",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List postsJson =
            data['data'] ??
            data['posts'] ??
            data['feed'] ??
            data['results'] ??
            [];
        print("PostService: Fetched ${postsJson.length} posts");
        return postsJson.map((json) => PostModel.fromJson(json)).toList();
      } else {
        print("PostService: Backend error ${response.statusCode} on Feed");
        return [];
      }
      return [];
    } catch (e) {
      print("PostService Error: $e");
      return [];
    }
  }

  Future<List<PostModel>> fetchUserPosts(String userId) async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.posts}/user/$userId",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List postsJson =
            data['data'] ?? data['posts'] ?? data['results'] ?? [];
        print("PostService: Fetched ${postsJson.length} user posts");
        return postsJson.map((json) => PostModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("PostService Error: $e");
      return [];
    }
  }

  Future<bool> createPost(
    String caption,
    String filePath,
    String mediaType,
  ) async {
    final response = await _apiService.postMultipart(
      ApiConstants.posts,
      {'caption': caption, 'mediaType': mediaType},
      'media', // Key used for posts
      filePath,
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> toggleLike(String postId) async {
    try {
      var response = await _apiService.post(ApiConstants.likes, {
        'postId': postId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) return true;

      response = await _apiService.post(
        "${ApiConstants.posts}/$postId/like",
        {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) return true;

      response = await _apiService.post(
        "${ApiConstants.likes}/post/$postId",
        {},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("PostService toggleLike error: $e");
      return false;
    }
  }

  Future<bool> addComment(String postId, String comment) async {
    final response = await _apiService.post(
      "${ApiConstants.posts}/$postId/comments",
      {'comment': comment},
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> deletePost(String postId) async {
    try {
      var response = await _apiService.delete("${ApiConstants.posts}/$postId");
      if (response.statusCode == 200 || response.statusCode == 204) return true;

      // Fallback for DELETE api/posts/delete/{id} if needed by this backend
      response = await _apiService.delete(
        "${ApiConstants.posts}/delete/$postId",
      );
      if (response.statusCode == 200 || response.statusCode == 204) return true;

      response = await _apiService.delete(
        "${ApiConstants.baseUrl}/posts/$postId",
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("PostService deletePost error: $e");
      return false;
    }
  }

  Future<bool> updatePost(String postId, String caption) async {
    try {
      var response = await _apiService.put("${ApiConstants.posts}/$postId", {
        'caption': caption,
      });
      if (response.statusCode == 200) return true;
      response = await _apiService.put(
        "${ApiConstants.posts}/$postId/caption",
        {'caption': caption},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("PostService updatePost error: $e");
      return false;
    }
  }
}
