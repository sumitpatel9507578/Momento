import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/post_model.dart';
import '../utils/app_colors.dart';
import '../widgets/post_card.dart';
import '../controllers/home_controller.dart';

class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PostModel post = Get.arguments as PostModel;
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: PostCard(
          post: post,
          onLike: () {
            // Find index in homeController.posts if it exists, or just toggle locally
            final index = homeController.posts.indexWhere((p) => p.postId == post.postId);
            if (index != -1) {
              homeController.toggleLike(index);
            }
          },
          onSave: () {
             final index = homeController.posts.indexWhere((p) => p.postId == post.postId);
             if (index != -1) {
               homeController.toggleSave(index);
             }
          },
          onFollow: () {
             final index = homeController.posts.indexWhere((p) => p.postId == post.postId);
             if (index != -1) {
               homeController.toggleFollow(index);
             }
          },
          onComment: () {},
          onMore: () {},
        ),
      ),
    );
  }
}
