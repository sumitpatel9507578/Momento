import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../widgets/post_card.dart';
import '../widgets/story_bar.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: false,
        title: const Text(
          'Momento',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/notifications'),
            icon: const Icon(Icons.favorite_border, size: 28),
          ),
          IconButton(
            onPressed: () => Get.toNamed('/chat-list'),
            icon: const Icon(Icons.chat_bubble_outline, size: 26),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshPosts,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: StoryBar()),
            const SliverToBoxAdapter(
              child: Divider(color: Colors.white10, height: 1),
            ),
            Obx(() {
              if (controller.isLoading.value && controller.posts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No posts found',
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextButton(
                          onPressed: controller.loadPosts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = controller.posts[index];
                  return PostCard(
                    post: post,
                    onLike: () => controller.toggleLike(index),
                    onSave: () => controller.toggleSave(index),
                    onFollow: () => controller.toggleFollow(index),
                    onComment: () {},
                    onRepost: () => controller.toggleRepost(index),
                  );
                }, childCount: controller.posts.length),
              );
            }),
            Obx(() {
              if (controller.isLoadingMore.value) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox(height: 100));
            }),
          ],
        ),
      ),
    );
  }
}
