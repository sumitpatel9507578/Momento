import 'package:get/get.dart';

import '../models/post_model.dart';
import '../services/fake_post_service.dart';

class HomeController extends GetxController {
  final FakePostService _postService = FakePostService();

  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  final currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }

  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  Future<void> loadPosts() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      _currentPage = 1;
      _hasMore = true;

      final result = await _postService.fetchPosts(
        page: _currentPage,
        limit: _pageSize,
      );

      posts.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Unable to load posts. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !_hasMore) return;

    try {
      isLoadingMore.value = true;
      _currentPage++;

      final result = await _postService.fetchPosts(
        page: _currentPage,
        limit: _pageSize,
      );

      if (result.isEmpty) {
        _hasMore = false;
      } else {
        posts.addAll(result);
      }
    } catch (e) {
      _currentPage--;
      Get.snackbar('Error', 'Failed to load more posts.');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshPosts() async {
    try {
      isRefreshing.value = true;
      _currentPage = 1;
      _hasMore = true;

      final result = await _postService.fetchPosts(
        page: _currentPage,
        limit: _pageSize,
      );

      posts.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Unable to refresh posts.';
    } finally {
      isRefreshing.value = false;
    }
  }

  void toggleLike(int index) {
    if (index < 0 || index >= posts.length) return;

    final post = posts[index];
    posts[index] = post.copyWith(
      isLiked: !post.isLiked,
      likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
  }

  void toggleSave(int index) {
    if (index < 0 || index >= posts.length) return;

    final post = posts[index];
    posts[index] = post.copyWith(isSaved: !post.isSaved);
  }

  void toggleFollow(int index) {
    if (index < 0 || index >= posts.length) return;

    final post = posts[index];
    posts[index] = post.copyWith(isFollowing: !post.isFollowing);
  }
}
