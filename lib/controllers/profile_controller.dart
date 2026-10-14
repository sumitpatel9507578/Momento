import 'dart:convert';

import 'package:get/get.dart';

import '../models/post_model.dart';
import '../models/reel_model.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../services/post_service.dart';
import '../services/reel_service.dart';
import '../utils/api_constants.dart';
import 'home_controller.dart';
import 'reel_controller.dart';

class ProfileController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final PostService _postService = Get.find<PostService>();
  final ReelService _reelService = Get.find<ReelService>();
  final UserRepository _userRepository = UserRepository();

  final userPosts = <PostModel>[].obs;
  final userReels = <ReelModel>[].obs;
  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final currentUser = Rxn<UserModel>();
  final selectedProfileTab = 0.obs;

  // Track if we are viewing someone else's profile
  String? _profileId;

  final followersList = <UserModel>[].obs;
  final followingList = <UserModel>[].obs;

  static String? extractUserId(dynamic args) {
    if (args == null) return null;
    if (args is String) return args.isNotEmpty ? args : null;
    if (args is int || args is double || args is num) return args.toString();
    if (args is UserModel) return args.uid.isNotEmpty ? args.uid : null;
    if (args is Map) {
      final extracted =
          (args['uid'] ??
                  args['id'] ??
                  args['_id'] ??
                  args['userId'] ??
                  args['user_id'])
              ?.toString();
      if (extracted != null && extracted.isNotEmpty) return extracted;
    }
    final str = args.toString();
    return str.isNotEmpty ? str : null;
  }

  @override
  void onInit() {
    super.onInit();
    final String? argId = extractUserId(Get.arguments);
    loadProfile(userId: argId);
  }

  Future<void> loadProfile({String? userId, bool forceRefresh = false}) async {
    _profileId = userId;

    if (currentUser.value != null &&
        !forceRefresh &&
        (userId == null || userId == 'me') &&
        (currentUser.value!.uid.isNotEmpty)) {
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final bool isMe = userId == null || userId == 'me';
      final endpoint = isMe ? ApiConstants.me : "${ApiConstants.users}/$userId";

      var response = await _apiService.get(endpoint);

      if (response.statusCode == 404 && !isMe) {
        response = await _apiService.get(
          "${ApiConstants.users}/profile/$userId",
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final profile = UserModel.fromMap(data['data']);
          currentUser.value = profile;
          final targetId = profile.uid;

          // Fetch posts, reels, followers, and following in parallel
          await Future.wait([
            _fetchPosts(targetId),
            _fetchReels(targetId),
            _fetchFollowersAndFollowing(targetId),
          ]);
        } else {
          errorMessage.value = data['message'] ?? 'Unable to fetch profile.';
        }
      } else {
        errorMessage.value =
            'Unable to fetch profile (${response.statusCode}).';
      }
      _fetchAllUsers();
    } catch (e) {
      print("Error loading profile: $e");
      errorMessage.value = 'Something went wrong while loading profile.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFollowUser(String targetUserId) async {
    try {
      final isNowFollowing = await _userRepository.followUser(targetUserId);
      if (isNowFollowing == null) {
        Get.snackbar('Error', 'Failed to update follow status');
        return;
      }

      if (currentUser.value != null && currentUser.value!.uid == targetUserId) {
        // Force UI refresh by re-assigning value
        final updatedUser = currentUser.value!.copyWith(
          isFollowing: isNowFollowing,
          followersCount: isNowFollowing
              ? currentUser.value!.followersCount + 1
              : (currentUser.value!.followersCount > 0
                    ? currentUser.value!.followersCount - 1
                    : 0),
        );
        currentUser.value = updatedUser;
        currentUser.refresh();
      } else if (currentUser.value != null &&
          (_profileId == null || _profileId == 'me')) {
        final currentFollowing = currentUser.value!.followingCount;
        final updatedUser = currentUser.value!.copyWith(
          followingCount: isNowFollowing
              ? currentFollowing + 1
              : (currentFollowing > 0 ? currentFollowing - 1 : 0),
        );
        currentUser.value = updatedUser;
        currentUser.refresh();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update follow status');
    }
  }

  Future<void> _fetchPosts(String userId) async {
    try {
      final posts = await _postService.fetchUserPosts(userId);
      userPosts.assignAll(posts);

      if (currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(
          postsCount: posts.length,
        );
      }
    } catch (e) {
      print("Error fetching posts: $e");
    }
  }

  Future<void> _fetchReels(String userId) async {
    try {
      final reels = await _reelService.fetchUserReels(userId);
      userReels.assignAll(reels);
    } catch (e) {
      print("Error fetching reels: $e");
    }
  }

  Future<void> _fetchFollowersAndFollowing(String userId) async {
    try {
      final myId = (await _apiService.getUserId()) ?? currentUser.value?.uid;

      final followers = await _userRepository.getFollowers(userId);
      final filteredFollowers = followers
          .where((u) => u.uid != myId && u.uid.isNotEmpty)
          .toList();
      followersList.assignAll(filteredFollowers);

      final following = await _userRepository.getFollowing(userId);
      final filteredFollowing = following
          .where((u) => u.uid != myId && u.uid.isNotEmpty)
          .toList();
      followingList.assignAll(filteredFollowing);

      if (currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(
          followersCount: filteredFollowers.length,
          followingCount: filteredFollowing.length,
        );
      }
    } catch (e) {
      print("Error fetching followers/following lists: $e");
    }
  }

  Future<void> _fetchAllUsers() async {
    try {
      final response = await _apiService.get("${ApiConstants.users}/search?q=");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List userJson = data['data'] ?? [];
        users.assignAll(
          userJson.map((json) => UserModel.fromMap(json)).toList(),
        );
      }
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  List<UserModel> get followers => followersList;
  List<UserModel> get following => followingList;

  void changeProfileTab(int index) {
    selectedProfileTab.value = index;
  }

  List<String> get currentTabImages {
    if (selectedProfileTab.value == 0) {
      return userPosts.map((p) => p.mediaUrl).toList();
    } else if (selectedProfileTab.value == 1) {
      return userReels
          .map((r) => r.thumbnail.isNotEmpty ? r.thumbnail : r.videoUrl)
          .toList();
    }
    return [];
  }

  Future<void> refreshProfile() async {
    await loadProfile(userId: _profileId, forceRefresh: true);
  }

  Future<void> refreshUsers() async {
    await loadProfile(userId: _profileId, forceRefresh: true);
  }

  Future<bool> deletePost(String postId) async {
    final success = await _postService.deletePost(postId);
    if (success) {
      userPosts.removeWhere((p) => p.postId == postId);
      Get.snackbar('Success', 'Post deleted successfully');
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().posts.removeWhere((p) => p.postId == postId);
      }
    } else {
      Get.snackbar('Error', 'Failed to delete post');
    }
    return success;
  }

  Future<bool> updatePostCaption(String postId, String newCaption) async {
    final success = await _postService.updatePost(postId, newCaption);
    if (success) {
      final index = userPosts.indexWhere((p) => p.postId == postId);
      if (index != -1) {
        userPosts[index] = userPosts[index].copyWith(caption: newCaption);
      }
      if (Get.isRegistered<HomeController>()) {
        final hIndex = Get.find<HomeController>().posts.indexWhere(
          (p) => p.postId == postId,
        );
        if (hIndex != -1) {
          Get.find<HomeController>().posts[hIndex] = Get.find<HomeController>()
              .posts[hIndex]
              .copyWith(caption: newCaption);
        }
      }
      Get.snackbar('Success', 'Post updated successfully');
    } else {
      Get.snackbar('Error', 'Failed to update post');
    }
    return success;
  }

  Future<bool> deleteReel(String reelId) async {
    final success = await _reelService.deleteReel(reelId);
    if (success) {
      userReels.removeWhere((r) => r.id == reelId);
      Get.snackbar('Success', 'Reel deleted successfully');
      if (Get.isRegistered<ReelController>()) {
        Get.find<ReelController>().reels.removeWhere((r) => r.id == reelId);
      }
    } else {
      Get.snackbar('Error', 'Failed to delete reel');
    }
    return success;
  }
}
