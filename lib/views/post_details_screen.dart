import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../utils/app_colors.dart';
import '../widgets/post_card.dart';

class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({super.key});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late PostModel _post;
  bool _isUpdatingLike = false;

  @override
  void initState() {
    super.initState();
    _post = Get.arguments as PostModel;
  }

  Future<void> _toggleLike() async {
    if (_isUpdatingLike) return;

    final previousPost = _post;
    final updatedPost = previousPost.copyWith(
      isLiked: !previousPost.isLiked,
      likesCount: previousPost.isLiked
          ? previousPost.likesCount - 1
          : previousPost.likesCount + 1,
    );
    setState(() {
      _isUpdatingLike = true;
      _post = updatedPost;
    });

    try {
      await Get.find<PostService>().toggleLike(previousPost.postId);
      _syncPost(updatedPost);
    } catch (error) {
      if (mounted) setState(() => _post = previousPost);
      Get.snackbar(
        'Like Error',
        error.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isUpdatingLike = false);
    }
  }

  Future<void> _deletePost() async {
    final deleted = await Get.find<PostService>().deletePost(_post.postId);
    if (!deleted) {
      Get.snackbar('Error', 'Failed to delete post');
      return;
    }

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().posts.removeWhere(
        (post) => post.postId == _post.postId,
      );
    }
    for (final tag in {'me', _post.userId}) {
      if (Get.isRegistered<ProfileController>(tag: tag)) {
        Get.find<ProfileController>(
          tag: tag,
        ).userPosts.removeWhere((post) => post.postId == _post.postId);
      }
    }
    if (!mounted) return;
    Get.back();
    Get.snackbar('Success', 'Post deleted successfully');
  }

  Future<void> _toggleSave() async {
    final wasSaved = _post.isSaved;
    final success = await Get.find<ChatController>().toggleSavePost(
      _post.postId,
      isSaved: wasSaved,
    );
    if (!success || !mounted) return;

    final updatedPost = _post.copyWith(isSaved: !wasSaved);
    setState(() => _post = updatedPost);
    _syncPost(updatedPost);
  }

  Future<void> _updateCaption(String caption) async {
    final updated = await Get.find<PostService>().updatePost(
      _post.postId,
      caption,
    );
    if (!updated) {
      Get.snackbar('Error', 'Failed to update post');
      return;
    }

    final updatedPost = _post.copyWith(caption: caption);
    if (!mounted) return;
    setState(() => _post = updatedPost);
    _syncPost(updatedPost);
    Get.snackbar('Success', 'Post updated successfully');
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

  @override
  Widget build(BuildContext context) {
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

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
        child: PostCard(
          post: _post,
          onLike: _toggleLike,
          onSave: _toggleSave,
          onFollow: () {
            final index = homeController.posts.indexWhere(
              (post) => post.postId == _post.postId,
            );
            if (index != -1) homeController.toggleFollow(index);
          },
          onComment: () {},
          onMore: () => PostCard.showPostOptionsBottomSheet(
            context,
            _post,
            onDelete: _deletePost,
            onUpdateCaption: _updateCaption,
          ),
        ),
      ),
    );
  }
}
