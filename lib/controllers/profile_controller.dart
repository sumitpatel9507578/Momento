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

  @override
  void onInit() {
    super.onInit();
    // Check if we have an ID passed as argument
    final String? argId = Get.arguments is String ? Get.arguments as String : null;
    loadProfile(userId: argId);
  }

  Future<void> loadProfile({String? userId, bool forceRefresh = false}) async {
    _profileId = userId;
    
    // Only load if data is null or if explicitly forced
    if (currentUser.value != null && !forceRefresh && userId == null) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final endpoint = userId != null ? "${ApiConstants.users}/$userId" : ApiConstants.me;
      final response = await _apiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final profile = UserModel.fromMap(data['data']);
          currentUser.value = profile;
          final targetId = profile.uid;

          // Fetch posts and reels
          await Future.wait([_fetchPosts(targetId), _fetchReels(targetId)]);
        }
      } else {
        errorMessage.value = 'Unable to fetch profile.';
      }
      _fetchAllUsers();
    } catch (e) {
      errorMessage.value = 'Something went wrong.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFollowUser(String targetUserId) async {
    try {
      final isNowFollowing = await _userRepository.followUser(targetUserId);
      
      if (isNowFollowing != null) {
        if (currentUser.value != null && currentUser.value!.uid == targetUserId) {
          // If we are on someone's profile and follow/unfollow them
          currentUser.value = currentUser.value!.copyWith(
            isFollowing: isNowFollowing,
            followersCount: isNowFollowing 
                ? currentUser.value!.followersCount + 1 
                : currentUser.value!.followersCount - 1
          );
        } else if (currentUser.value != null && _profileId == null) {
          // If we are on 'MY' profile and follow someone else (not usual from here)
          final currentFollowing = currentUser.value!.followingCount;
          currentUser.value = currentUser.value!.copyWith(
            followingCount: isNowFollowing ? currentFollowing + 1 : currentFollowing - 1,
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update follow status');
    }
  }

  Future<void> _fetchPosts(String userId) async {
    try {
      final posts = await _postService.fetchUserPosts(userId);
      userPosts.assignAll(posts);

      if (currentUser.value != null && currentUser.value!.uid == userId) {
        currentUser.value = currentUser.value!.copyWith(postsCount: posts.length);
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

  Future<void> _fetchAllUsers() async {
    try {
      final response = await _apiService.get("${ApiConstants.users}/search?q=");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List userJson = data['data'] ?? [];
        users.assignAll(userJson.map((json) => UserModel.fromMap(json)).toList());
      }
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  List<UserModel> get followers => users;
  List<UserModel> get following => users;

  void changeProfileTab(int index) {
    selectedProfileTab.value = index;
  }

  List<String> get currentTabImages {
    if (selectedProfileTab.value == 0) {
      return userPosts.map((p) => p.mediaUrl).toList();
    } else if (selectedProfileTab.value == 1) {
      return userReels.map((r) => r.videoUrl).toList();
    }
    return [];
  }

  Future<void> refreshProfile() async {
    await loadProfile(userId: _profileId, forceRefresh: true);
  }

  Future<void> refreshUsers() async {
    await loadProfile(userId: _profileId, forceRefresh: true);
  }
}
