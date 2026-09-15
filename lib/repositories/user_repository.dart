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
      final response = await _apiService.get("${ApiConstants.users}/$uid");
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
        return data['isFollowing']; // Return the actual toggle status from backend
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
      if (userData == null) return false;

      final userId = (userData['id'] ?? userData['uid']).toString();

      final response = await _apiService.putMultipart(
        "${ApiConstants.users}/$userId",
        data,
        imagePath != null ? "profileImage" : null,
        imagePath,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          await _apiService.saveUser(result['data']);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }
}
