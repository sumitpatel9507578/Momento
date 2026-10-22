import 'dart:convert';

import 'package:get/get.dart';

import '../models/post_model.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';
import 'profile_controller.dart';

class ExploreController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final UserRepository _userRepository = UserRepository();

  final searchResults = <UserModel>[].obs;
  final suggestedUsers = <UserModel>[].obs;
  final explorePosts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingExplore = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSuggestions();
    fetchExplorePosts();

    debounce(searchQuery, (String query) {
      if (query.isNotEmpty) {
        searchUsers(query);
      } else {
        searchResults.clear();
      }
    }, time: const Duration(milliseconds: 500));
  }

  Future<void> loadSuggestions() async {
    try {
      final response = await _apiService.get("${ApiConstants.searchUsers}?q=");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List userJson = data['data'] ?? [];
        suggestedUsers.assignAll(
          userJson.map((json) => UserModel.fromMap(json)).toList(),
        );
      }
    } catch (e) {
      print("Search Suggestions Error: $e");
    }
  }

  Future<void> fetchExplorePosts() async {
    try {
      isLoadingExplore.value = true;
      final response = await _apiService.get(
        "${ApiConstants.posts}?page=1&limit=30",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List postsJson = data['data'] ?? [];
        explorePosts.assignAll(
          postsJson.map((json) => PostModel.fromJson(json)).toList(),
        );
      }
    } catch (e) {
      print("Explore Posts Error: $e");
    } finally {
      isLoadingExplore.value = false;
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isLoading.value = true;
      final sanitizedQuery = query.trim();
      final response = await _apiService.get(
        "${ApiConstants.searchUsers}?q=$sanitizedQuery",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List userJson = data['data'] ?? [];

        if (userJson.isNotEmpty) {
          searchResults.assignAll(
            userJson.map((json) => UserModel.fromMap(json)).toList(),
          );
        } else {
          searchResults.clear();
        }
      } else if (response.statusCode == 500) {
        // Fallback for 500 Error
        final allUsersResp = await _apiService.get("${ApiConstants.users}/search?q=");
        if (allUsersResp.statusCode == 200) {
          final data = jsonDecode(allUsersResp.body);
          final List userJson = data['data'] ?? [];
          final allUsers = userJson
              .map((json) => UserModel.fromMap(json))
              .toList();

          searchResults.assignAll(
            allUsers
                .where(
                  (u) =>
                      u.username.toLowerCase().contains(
                        sanitizedQuery.toLowerCase(),
                      ) ||
                      u.name.toLowerCase().contains(
                        sanitizedQuery.toLowerCase(),
                      ),
                )
                .toList(),
          );
        }
      }
    } catch (e) {
      print("Search Error: $e");
      searchResults.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFollow(String targetUserId) async {
    try {
      final isNowFollowing = await _userRepository.followUser(targetUserId);

      if (isNowFollowing != null) {
        // Sync Search Results
        final sIndex = searchResults.indexWhere((u) => u.uid == targetUserId);
        if (sIndex != -1) {
          searchResults[sIndex] = searchResults[sIndex].copyWith(
            isFollowing: isNowFollowing,
            followersCount: isNowFollowing
                ? searchResults[sIndex].followersCount + 1
                : searchResults[sIndex].followersCount - 1,
          );
        }

        // Sync Suggestions
        final sugIndex = suggestedUsers.indexWhere(
          (u) => u.uid == targetUserId,
        );
        if (sugIndex != -1) {
          loadSuggestions();
        }

        // Sync with ProfileController
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().refreshProfile();
        }
        if (Get.isRegistered<ProfileController>(tag: 'me')) {
          Get.find<ProfileController>(tag: 'me').refreshProfile();
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not update follow status');
    }
  }
}
