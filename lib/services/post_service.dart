import 'dart:convert';

import 'package:http/http.dart' as http;

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
    final user = await _apiService.getUser();
    final userId = (user?['id'] ?? user?['uid'] ?? user?['userId'] ?? '')
        .toString();
    final username = (user?['username'] ?? user?['name'] ?? 'User').toString();

    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      try {
        final jsonBody = <String, dynamic>{
          'mediaUrl': filePath,
          'media_url': filePath,
          'url': filePath,
          'media': filePath,
          'image': filePath,
          'mediaType': mediaType,
          'media_type': mediaType,
          'caption': caption.isEmpty ? 'Momento' : caption,
          if (userId.isNotEmpty) 'userId': userId,
          if (username.isNotEmpty) 'username': username,
        };
        final response = await _apiService.post(ApiConstants.posts, jsonBody);
        if (response.statusCode == 201 || response.statusCode == 200) {
          _logMediaUrl(response.body);
          return true;
        }
      } catch (e) {
        print("PostService Network URL Post error: $e");
      }
    }

    final bodyFields = <String, String>{
      'caption': caption.isEmpty ? 'Momento' : caption,
      'mediaType': mediaType,
      'media_type': mediaType,
      'type': mediaType,
      if (userId.isNotEmpty) 'userId': userId,
      if (userId.isNotEmpty) 'user_id': userId,
      if (username.isNotEmpty) 'username': username,
    };

    // 1. Try Multipart key 'media'
    var response = await _apiService.postMultipart(
      ApiConstants.posts,
      bodyFields,
      'media',
      filePath,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      _logMediaUrl(response.body);
      return true;
    }

    // 2. Try Multipart key 'file'
    response = await _apiService.postMultipart(
      ApiConstants.posts,
      bodyFields,
      'file',
      filePath,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      _logMediaUrl(response.body);
      return true;
    }

    // 3. Try Multipart key 'image'
    response = await _apiService.postMultipart(
      ApiConstants.posts,
      bodyFields,
      'image',
      filePath,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      _logMediaUrl(response.body);
      return true;
    }

    return false;
  }

  Future<bool> createCarouselPost(
    String caption,
    List<String> filePaths, {
    String? location,
  }) async {
    if (filePaths.isEmpty) return false;
    if (filePaths.length == 1) {
      final isVid = filePaths.first.toLowerCase().contains('.mp4') ||
          filePaths.first.toLowerCase().contains('.mov');
      return createPost(caption, filePaths.first, isVid ? 'video' : 'image');
    }

    final user = await _apiService.getUser();
    final userId = (user?['id'] ?? user?['uid'] ?? user?['userId'] ?? '')
        .toString();
    final username = (user?['username'] ?? user?['name'] ?? 'User').toString();

    final allNetwork = filePaths.every(
      (p) => p.startsWith('http://') || p.startsWith('https://'),
    );
    if (allNetwork) {
      try {
        final jsonBody = <String, dynamic>{
          'mediaUrls': filePaths,
          'media_urls': filePaths,
          'mediaUrl': filePaths.first,
          'mediaType': 'carousel',
          'caption': caption.isEmpty ? 'Momento' : caption,
          if (location != null && location.isNotEmpty) 'location': location,
          if (userId.isNotEmpty) 'userId': userId,
          if (username.isNotEmpty) 'username': username,
        };
        final response = await _apiService.post(ApiConstants.posts, jsonBody);
        if (response.statusCode == 201 || response.statusCode == 200) {
          _logMediaUrl(response.body);
          return true;
        }
      } catch (e) {
        print("PostService Carousel Network error: $e");
      }
    }

    final firstPath = filePaths.first;
    final isVideo = firstPath.toLowerCase().contains('.mp4') ||
        firstPath.toLowerCase().contains('.mov');

    final bodyFields = <String, String>{
      'caption': caption.isEmpty ? 'Momento' : caption,
      'mediaType': isVideo ? 'video' : 'image',
      if (location != null && location.isNotEmpty) 'location': location,
      if (userId.isNotEmpty) 'userId': userId,
      if (username.isNotEmpty) 'username': username,
    };

    var response = await _apiService.postMultipart(
      ApiConstants.posts,
      bodyFields,
      'media',
      firstPath,
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      _logMediaUrl(response.body);
      return true;
    }

    return false;
  }

  void _logMediaUrl(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      final mediaUrl =
          data['data']?['mediaUrl'] ??
          data['mediaUrl'] ??
          data['url'] ??
          data['data']?['url'];
      print("☁️ Post Media Stored URL: $mediaUrl");
    } catch (_) {}
  }

  Map<String, dynamic>? _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> toggleLike(String postId) async {
    final user = await _apiService.getUser();
    final userId = (user?['id'] ?? user?['uid'] ?? user?['userId'] ?? '')
        .toString();

    final body = <String, dynamic>{
      'postId': postId,
      'post_id': postId,
      if (userId.isNotEmpty) 'userId': userId,
      if (userId.isNotEmpty) 'user_id': userId,
    };

    String errorMessage = 'Could not update like status';

    // 1. Try POST /api/likes/post/{postId}
    try {
      var response = await _apiService.post(
        "${ApiConstants.likes}/post/$postId",
        body,
      );
      final decoded = _decodeResponse(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded == null || decoded['success'] != false) return;
        errorMessage = decoded['message']?.toString() ?? errorMessage;
      } else if (decoded != null && decoded['message'] != null) {
        errorMessage = decoded['message'].toString();
      }
    } catch (_) {}

    // 2. Try POST /api/posts/{postId}/like
    try {
      var response = await _apiService.post(
        "${ApiConstants.posts}/$postId/like",
        body,
      );
      final decoded = _decodeResponse(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded == null || decoded['success'] != false) return;
        errorMessage = decoded['message']?.toString() ?? errorMessage;
      } else if (decoded != null && decoded['message'] != null) {
        errorMessage = decoded['message'].toString();
      }
    } catch (_) {}

    // 3. Try POST /api/likes
    try {
      var response = await _apiService.post(ApiConstants.likes, body);
      final decoded = _decodeResponse(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded == null || decoded['success'] != false) return;
        errorMessage = decoded['message']?.toString() ?? errorMessage;
      } else if (decoded != null && decoded['message'] != null) {
        errorMessage = decoded['message'].toString();
      }
    } catch (_) {}

    throw Exception(errorMessage);
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
      final body = {'postId': postId, 'post_id': postId, 'id': postId};

      bool isSuccess(http.Response response) {
        if (response.statusCode != 200 &&
            response.statusCode != 201 &&
            response.statusCode != 204) {
          return false;
        }
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['success'] == false) return false;
        } catch (_) {}
        return true;
      }

      // 1. DELETE /api/posts/{postId}
      var response = await _apiService.delete("${ApiConstants.posts}/$postId");
      if (isSuccess(response)) return true;

      // 2. DELETE /api/posts/delete/{postId}
      response = await _apiService.delete(
        "${ApiConstants.posts}/delete/$postId",
      );
      if (isSuccess(response)) return true;

      // 3. POST /api/posts/{postId}/delete
      response = await _apiService.post(
        "${ApiConstants.posts}/$postId/delete",
        body,
      );
      if (isSuccess(response)) return true;

      // 4. POST /api/posts/delete
      response = await _apiService.post("${ApiConstants.posts}/delete", body);
      if (isSuccess(response)) return true;

      // 5. POST /api/posts/{postId}/remove
      response = await _apiService.post(
        "${ApiConstants.posts}/$postId/remove",
        body,
      );
      if (isSuccess(response)) return true;

      // 6. DELETE /api/baseUrl/posts/$postId
      response = await _apiService.delete(
        "${ApiConstants.baseUrl}/posts/$postId",
      );
      return isSuccess(response);
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

  Future<bool> toggleRepost(String postId, {String? note}) async {
    try {
      final user = await _apiService.getUser();
      final userId = (user?['id'] ?? user?['uid'] ?? user?['userId'] ?? '')
          .toString();
      final body = <String, dynamic>{
        'postId': int.tryParse(postId) ?? postId,
        'post_id': int.tryParse(postId) ?? postId,
        'itemType': 'post',
        if (userId.isNotEmpty) 'userId': userId,
        if (note != null && note.isNotEmpty) ...{
          'note': note,
          'repostNote': note,
          'repost_note': note,
        },
      };

      final endpoints = [
        "${ApiConstants.posts}/$postId/repost",
        ApiConstants.reposts,
        "${ApiConstants.posts}/$postId/reposts",
        "${ApiConstants.posts}/repost",
        "${ApiConstants.posts}/$postId/share",
      ];

      for (final endpoint in endpoints) {
        final response = await _apiService.post(endpoint, body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        }
      }

      return true;
    } catch (e) {
      print("PostService toggleRepost error: $e");
      return true;
    }
  }
}
