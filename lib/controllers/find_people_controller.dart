import 'dart:convert';

import 'package:get/get.dart';

import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';

class FindPeopleController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  final UserRepository _userRepository = UserRepository();

  final users = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final searchText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      final currentUserId = await apiService.getUserId();

      var response = await apiService.get("${ApiConstants.users}/search?q=");
      if (response.statusCode != 200) {
        response = await apiService.get(ApiConstants.users);
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        if (body['success'] == true || body['data'] != null) {
          final List data = body['data'] ?? body['users'] ?? [];

          final parsedUsers = data
              .map(
                (user) => {
                  'id':
                      user['id'] ??
                      user['userId'] ??
                      user['uid'] ??
                      user['_id'],
                  'name': user['name'] ?? user['full_name'] ?? '',
                  'username': user['username'] ?? '',
                  'image': user['profileImage'] ?? user['profile_image'] ?? '',
                  'isFollowed':
                      user['isFollowing'] ?? user['is_followed'] ?? false,
                },
              )
              .where((user) => user['id']?.toString() != currentUserId)
              .toList();

          users.assignAll(parsedUsers);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load users',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchUsers(String query) async {
    searchText.value = query;

    if (query.trim().isEmpty) {
      await loadUsers();
      return;
    }

    try {
      isLoading.value = true;
      final currentUserId = await apiService.getUserId();

      final url = '${ApiConstants.searchUsers}?q=${Uri.encodeComponent(query)}';

      final response = await apiService.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        if (body['success'] == true || body['data'] != null) {
          final List data = body['data'] ?? body['users'] ?? [];

          final parsedUsers = data
              .map(
                (user) => {
                  'id':
                      user['id'] ??
                      user['userId'] ??
                      user['uid'] ??
                      user['_id'],
                  'name': user['name'] ?? user['full_name'] ?? '',
                  'username': user['username'] ?? '',
                  'image': user['profileImage'] ?? user['profile_image'] ?? '',
                  'isFollowed':
                      user['isFollowing'] ?? user['is_followed'] ?? false,
                },
              )
              .where((user) => user['id']?.toString() != currentUserId)
              .toList();

          users.assignAll(parsedUsers);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Search failed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFollow(int index) async {
    final user = users[index];

    final userId = user['id'];

    if (userId == null) {
      Get.snackbar(
        'Error',
        'User ID not found',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      user['isLoading'] = true;
      users.refresh();

      final bool? isFollowing = await _userRepository.followUser(
        userId.toString(),
      );

      if (isFollowing != null) {
        user['isFollowed'] = isFollowing;

        Get.snackbar(
          'Success',
          isFollowing
              ? '@${user['username']} is now followed'
              : 'Unfollowed @${user['username']}',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Follow failed',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong while following',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      user['isLoading'] = false;
      users.refresh();
    }
  }

  void continueToHome() {
    Get.offAllNamed('/home');
  }
}
