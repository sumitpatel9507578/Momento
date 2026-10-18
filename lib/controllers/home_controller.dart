import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/chat_controller.dart';
import 'package:momento/controllers/profile_controller.dart';
import 'package:momento/controllers/reel_controller.dart';
import 'package:momento/models/post_model.dart';
import 'package:momento/repositories/user_repository.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/services/post_service.dart';

class HomeController extends GetxController {
  final PostService _postService = Get.find<PostService>();
  final UserRepository _userRepository = UserRepository();

  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  final currentIndex = 0.obs;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  void changeTab(int index) {
    currentIndex.value = index;

    // Handle Reel playback when switching tabs
    if (Get.isRegistered<ReelController>()) {
      final reelController = Get.find<ReelController>();
      if (index == 3) {
        reelController.resumeCurrentVideo();
      } else {
        reelController.pauseAllVideos();
      }
    }

    if (index == 0) {}
  }

  Future<void> loadPosts() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      _currentPage = 1;
      _hasMore = true;

      final result = await _postService.fetchPosts(page: _currentPage);
      posts.assignAll(result);

      if (result.isEmpty && !isLoading.value) {
        errorMessage.value = 'Feed is empty. Start following users!';
      }

      if (result.length < 10) {
        _hasMore = false;
      }
    } catch (e) {
      print("Home Load Error: $e");
      errorMessage.value = 'Something went wrong. Pull to refresh.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !_hasMore) return;

    try {
      isLoadingMore.value = true;
      _currentPage++;

      final result = await _postService.fetchPosts(page: _currentPage);

      if (result.isEmpty) {
        _hasMore = false;
      } else {
        posts.addAll(result);
        if (result.length < 10) {
          _hasMore = false;
        }
      }
    } catch (e) {
      _currentPage--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshPosts() async {
    try {
      isRefreshing.value = true;
      _currentPage = 1;
      _hasMore = true;

      final result = await _postService.fetchPosts(page: _currentPage);
      posts.assignAll(result);

      if (result.length < 10) {
        _hasMore = false;
      }
    } catch (e) {
      print("Home Refresh Error: $e");
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> toggleLike(int index) async {
    if (index < 0 || index >= posts.length) return;

    final post = posts[index];
    final originalState = post.isLiked;
    final originalLikes = post.likesCount;

    // Optimistic UI update
    posts[index] = post.copyWith(
      isLiked: !post.isLiked,
      likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
    );

    try {
      await _postService.toggleLike(post.postId);
      Get.snackbar(
        'Success',
        posts[index].isLiked ? 'Post liked' : 'Post unliked',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      // Revert on error
      posts[index] = post.copyWith(
        isLiked: originalState,
        likesCount: originalLikes,
      );
      Get.snackbar(
        'Like Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> toggleSave(int index) async {
    if (index < 0 || index >= posts.length) return;
    final post = posts[index];
    final isSaved = post.isSaved;
    final updatedPost = post.copyWith(isSaved: !isSaved);
    posts[index] = updatedPost;

    try {
      final success = await Get.find<ChatController>().toggleSavePost(
        post.postId,
        isSaved: isSaved,
      );
      if (!success) {
        posts[index] = post;
        return;
      }
      _updateProfilePostSavedState(updatedPost);
    } catch (error) {
      posts[index] = post;
      Get.snackbar('Error', 'Could not update saved post');
    }
  }

  void _updateProfilePostSavedState(PostModel post) {
    for (final tag in {'me', post.userId}) {
      if (!Get.isRegistered<ProfileController>(tag: tag)) continue;
      final profilePosts = Get.find<ProfileController>(tag: tag).userPosts;
      final index = profilePosts.indexWhere(
        (item) => item.postId == post.postId,
      );
      if (index != -1) profilePosts[index] = post;
    }
  }

  Future<void> toggleFollow(int index) async {
    if (index < 0 || index >= posts.length) return;
    final post = posts[index];
    final originalState = post.isFollowing;

    // Optimistic UI update
    posts[index] = post.copyWith(isFollowing: !post.isFollowing);

    try {
      final isFollowing = await _userRepository.followUser(post.userId);
      if (isFollowing == null) throw Exception('API failure');

      // Sync UI with actual server state
      posts[index] = post.copyWith(isFollowing: isFollowing);
    } catch (e) {
      // Revert on error
      posts[index] = post.copyWith(isFollowing: originalState);
      Get.snackbar('Error', 'Could not update follow status');
    }
  }

  Future<bool> deletePost(String postId) async {
    final success = await _postService.deletePost(postId);
    if (success) {
      posts.removeWhere((p) => p.postId == postId);
      Get.snackbar('Success', 'Post deleted successfully');
    } else {
      Get.snackbar('Error', 'Failed to delete post');
    }
    return success;
  }

  Future<bool> updatePostCaption(String postId, String newCaption) async {
    final success = await _postService.updatePost(postId, newCaption);
    if (success) {
      final index = posts.indexWhere((p) => p.postId == postId);
      if (index != -1) {
        posts[index] = posts[index].copyWith(caption: newCaption);
      }
      Get.snackbar('Success', 'Post updated successfully');
    } else {
      Get.snackbar('Error', 'Failed to update post');
    }
    return success;
  }

  Future<void> toggleRepost(
    int index, {
    String? note,
    bool removeNote = false,
  }) async {
    if (index < 0 || index >= posts.length) return;

    final post = posts[index];
    final originalState = post.isReposted;
    final originalCount = post.repostsCount;
    final originalNote = post.repostNote;
    final originalAvatar = post.repostUserAvatar;

    Map<String, dynamic>? currentUser;
    if (Get.isRegistered<ApiService>()) {
      currentUser = await Get.find<ApiService>().getUser();
    }
    final userAvatar =
        (currentUser?['profileImage'] ??
                currentUser?['profile_image'] ??
                currentUser?['profileimage'] ??
                currentUser?['avatar'] ??
                '')
            .toString();

    final bool newRepostedState = removeNote ? false : true;
    final newCount = newRepostedState
        ? (originalState ? originalCount : originalCount + 1)
        : (originalCount > 0 ? originalCount - 1 : 0);

    final String finalNote = (note != null && note.trim().isNotEmpty)
        ? note.trim()
        : 'Drop an emoji...';

    // Optimistic UI update
    posts[index] = post.copyWith(
      isReposted: newRepostedState,
      repostsCount: newCount,
      repostNote: newRepostedState ? finalNote : null,
      repostUserAvatar: newRepostedState ? userAvatar : null,
    );

    Get.snackbar(
      newRepostedState ? 'Reposted' : 'Removed',
      newRepostedState ? 'Post reposted with note!' : 'Repost removed',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: newRepostedState ? Colors.green : Colors.grey[800],
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    try {
      await _postService.toggleRepost(
        post.postId,
        note: newRepostedState ? finalNote : null,
      );
    } catch (_) {
      // Revert on error
      posts[index] = post.copyWith(
        isReposted: originalState,
        repostsCount: originalCount,
        repostNote: originalNote,
        repostUserAvatar: originalAvatar,
      );
    }
  }
}
