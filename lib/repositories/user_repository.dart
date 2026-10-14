import 'dart:convert';

import 'package:get/get.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';

class UserRepository {
  final ApiService _apiService = Get.find<ApiService>();

  Future<UserModel?> getMyProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.me);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return UserModel.fromMap(data['data']);
        }
      }
      return null;
    } catch (e) {
      print("Error fetching my profile: $e");
      return null;
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      var response = await _apiService.get("${ApiConstants.users}/$uid");
      if (response.statusCode == 404) {
        // Fallback for API variants that place user ID after different path or in search
        response = await _apiService.get("${ApiConstants.users}/profile/$uid");
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return UserModel.fromMap(data['data']);
        }
      }
      return null;
    } catch (e) {
      print("Error fetching user $uid: $e");
      return null;
    }
  }

  Future<bool?> followUser(String userId) async {
    try {
      final response = await _apiService.post(
        "${ApiConstants.follows}/$userId",
        {},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("DEBUG follow response: $data");
        final dynamic rawStatus =
            data['isFollowing'] ??
            data['is_following'] ??
            data['data']?['isFollowing'] ??
            data['data']?['is_following'] ??
            data['following'];
        if (rawStatus != null) {
          return rawStatus == true || rawStatus == 1 || rawStatus == 'true';
        }
        return true;
      }
      return null;
    } catch (e) {
      print("Error following user: $e");
      return null;
    }
  }

  Future<bool> updateProfile(
    Map<String, String> data,
    String? imagePath,
  ) async {
    try {
      final userData = await _apiService.getUser();
      final userId = (userData?['id'] ?? userData?['uid'] ?? '').toString();

      final endpoints = [
        ApiConstants.me,
        if (userId.isNotEmpty) "${ApiConstants.users}/$userId",
      ];

      for (final endpoint in endpoints) {
        if (imagePath == null) {
          final response = await _apiService.put(endpoint, data);
          if (response.statusCode == 200) {
            final result = jsonDecode(response.body);
            if (result is Map && (result['success'] == true || result['data'] != null)) {
              if (result['data'] != null) {
                await _apiService.saveUser(result['data']);
              }
              return true;
            }
          }
        } else {
          final keysToTry = ['profile_image', 'profileImage', 'image', 'file', 'media'];
          for (final key in keysToTry) {
            final response = await _apiService.putMultipart(endpoint, data, key, imagePath);
            if (response.statusCode == 200) {
              final result = jsonDecode(response.body);
              if (result is Map && (result['success'] == true || result['data'] != null)) {
                if (result['data'] != null) {
                  await _apiService.saveUser(result['data']);
                }
                return true;
              }
            }
          }
        }
      }

      return false;
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }

  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      var response = await _apiService.get(
        "${ApiConstants.users}/$userId/followers",
      );
      if (response.statusCode == 404) {
        response = await _apiService.get(
          "${ApiConstants.follows}/$userId/followers",
        );
      }
      if (response.statusCode == 404) {
        response = await _apiService.get(
          "${ApiConstants.baseUrl}/followers/$userId",
        );
      }
      if (response.statusCode == 404) {
        response = await _apiService.get(
          "${ApiConstants.users}/followers/$userId",
        );
      }
      if (response.statusCode == 404) {
        response = await _apiService.get(
          "${ApiConstants.baseUrl}/users/followers/$userId",
        );
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List userJson = [];
        if (decoded is List) {
          userJson = decoded;
        } else if (decoded is Map) {
          userJson =
              decoded['data'] ?? decoded['followers'] ?? decoded['users'] ?? [];
        }
        return userJson.map((json) => UserModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching followers: $e");
      return [];
    }
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      var response = await _apiService.get(
        "${ApiConstants.users}/$userId/following",
      );
      if (response.statusCode == 404) {
        response = await _apiService.get(
          "${ApiConstants.follows}/$userId/following",
        );
      }
      if (response.statusCode == 404) {
        response = await _apiService.get(
          "${ApiConstants.baseUrl}/following/$userId",
        );
      }
      if (response.statusCode == 404) {
        response = await _apiService.get(
          "${ApiConstants.users}/following/$userId",
        );
      }
      if (response.statusCode == 404) {
        response = await _apiService.get(
          "${ApiConstants.baseUrl}/users/following/$userId",
        );
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List userJson = [];
        if (decoded is List) {
          userJson = decoded;
        } else if (decoded is Map) {
          userJson =
              decoded['data'] ?? decoded['following'] ?? decoded['users'] ?? [];
        }
        return userJson.map((json) => UserModel.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching following: $e");
      return [];
    }
  }
}
