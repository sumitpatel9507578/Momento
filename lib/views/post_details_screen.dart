import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../utils/app_colors.dart';
import '../widgets/post_card.dart';

class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postRx = (Get.arguments as PostModel).obs;
    final isUpdatingLike = false.obs;

    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    Future<void> toggleLike() async {
      if (isUpdatingLike.value) return;

      final previousPost = postRx.value;
      final updatedPost = previousPost.copyWith(
        isLiked: !previousPost.isLiked,
        likesCount: previousPost.isLiked
            ? previousPost.likesCount - 1
            : previousPost.likesCount + 1,
      );

      isUpdatingLike.value = true;
      postRx.value = updatedPost;

      try {
        await Get.find<PostService>().toggleLike(previousPost.postId);
        _syncPost(updatedPost);
      } catch (error) {
        postRx.value = previousPost;
        Get.snackbar(
          'Like Error',
          error.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isUpdatingLike.value = false;
      }
    }

    Future<void> deletePost() async {
      final currentPost = postRx.value;
      final deleted =
          await Get.find<PostService>().deletePost(currentPost.postId);
      if (!deleted) {
        Get.snackbar('Error', 'Failed to delete post');
        return;
      }

      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().posts.removeWhere(
          (post) => post.postId == currentPost.postId,
        );
      }
      for (final tag in {'me', currentPost.userId}) {
        if (Get.isRegistered<ProfileController>(tag: tag)) {
          Get.find<ProfileController>(
            tag: tag,
          ).userPosts.removeWhere((post) => post.postId == currentPost.postId);
        }
      }
      Get.back();
      Get.snackbar('Success', 'Post deleted successfully');
    }

    Future<void> toggleSave() async {
      final currentPost = postRx.value;
      final wasSaved = currentPost.isSaved;
      final success = await Get.find<ChatController>().toggleSavePost(
        currentPost.postId,
        isSaved: wasSaved,
      );
      if (!success) return;

      final updatedPost = currentPost.copyWith(isSaved: !wasSaved);
      postRx.value = updatedPost;
      _syncPost(updatedPost);
    }

    Future<void> updateCaption(String caption) async {
      final currentPost = postRx.value;
      final updated = await Get.find<PostService>().updatePost(
        currentPost.postId,
        caption,
      );
      if (!updated) {
        Get.snackbar('Error', 'Failed to update post');
        return;
      }

      final updatedPost = currentPost.copyWith(caption: caption);
      postRx.value = updatedPost;
      _syncPost(updatedPost);
      Get.snackbar('Success', 'Post updated successfully');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Obx(
          () => PostCard(
            post: postRx.value,
            onLike: toggleLike,
            onSave: toggleSave,
            onFollow: () {
              final index = homeController.posts.indexWhere(
                (post) => post.postId == postRx.value.postId,
              );
              if (index != -1) homeController.toggleFollow(index);
            },
            onComment: () {},
            onMore: () => PostCard.showPostOptionsBottomSheet(
              context,
              postRx.value,
              onDelete: deletePost,
              onUpdateCaption: updateCaption,
            ),
          ),
        ),
      ),
    );
  }

  void _syncPost(PostModel updatedPost) {
    if (Get.isRegistered<HomeController>()) {
      final posts = Get.find<HomeController>().posts;
      final index = posts.indexWhere(
        (post) => post.postId == updatedPost.postId,
      );
      if (index != -1) posts[index] = updatedPost;
    }

    for (final tag in {'me', updatedPost.userId}) {
      if (Get.isRegistered<ProfileController>(tag: tag)) {
        final posts = Get.find<ProfileController>(tag: tag).userPosts;
        final index = posts.indexWhere(
          (post) => post.postId == updatedPost.postId,
        );
        if (index != -1) posts[index] = updatedPost;
      }
    }
  }
}
