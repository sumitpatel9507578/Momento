import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../utils/app_colors.dart';
import '../widgets/post_card.dart';
import '../widgets/story_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Momento',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/notifications'),
            icon: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: () => Get.toNamed('/chat-list'),
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: homeController.refreshPosts,
        color: AppColors.purple,
        backgroundColor: AppColors.surface,
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
              homeController.loadMorePosts();
            }
            return true;
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: StoryBar()),
              const SliverToBoxAdapter(
                child: Divider(color: Colors.white10, height: 1),
              ),
              Obx(() {
                if (homeController.isLoading.value &&
                    homeController.posts.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.purple),
                    ),
                  );
                }

                if (homeController.posts.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white24,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No posts yet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: homeController.loadPosts,
                            child: const Text(
                              'Refresh Feed',
                              style: TextStyle(color: AppColors.purple),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = homeController.posts[index];
                    return PostCard(
                      post: post,
                      onLike: () => homeController.toggleLike(index),
                      onSave: () => homeController.toggleSave(index),
                      onFollow: () => homeController.toggleFollow(index),
                      onComment: () {},
                      onMore: () {},
                    );
                  }, childCount: homeController.posts.length),
                );
              }),
              Obx(
                () => homeController.isLoadingMore.value
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.purple,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    : const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ),
<<<<<<< HEAD
            ),
          ),

          // Glass Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassContainer(
              height: size.height * 0.12,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              padding: EdgeInsets.fromLTRB(
                width * 0.06,
                MediaQuery.of(context).padding.top + 8,
                width * 0.04,
                8,
              ),
              blur: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Momento',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.07,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.add_box_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Network Status Banner
          Obx(() {
            final networkController = Get.find<NetworkController>();
            if (networkController.isConnected.value) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  child: const Center(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(
        () => Container(
          margin: EdgeInsets.fromLTRB(
            width * 0.03,
            0,
            width * 0.03,
            size.height * 0.015,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {
                    homeController.changeTab(0);
                    Get.offAllNamed(AppRoutes.home);
                  },
                  icon: Icon(
                    Icons.home_rounded,
                    color: homeController.currentIndex.value == 0
                        ? Colors.white
                        : AppColors.grey,
                    size: width * 0.065,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    homeController.changeTab(1);
                    Get.toNamed(AppRoutes.search);
                  },
                  icon: Icon(
                    Icons.explore_outlined,
                    color: homeController.currentIndex.value == 1
                        ? Colors.white
                        : AppColors.grey,
                    size: width * 0.065,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    homeController.changeTab(2);
                  },
                  child: Container(
                    width: width * 0.13,
                    height: width * 0.13,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: width * 0.075,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    homeController.changeTab(3);
                    Get.toNamed(AppRoutes.reels);
                  },
                  icon: Icon(
                    Icons.play_circle_outline_rounded,
                    color: homeController.currentIndex.value == 3
                        ? Colors.white
                        : AppColors.grey,
                    size: width * 0.065,
                  ),
                ),

                IconButton(
                  onPressed: () {
                    homeController.changeTab(4);
                    Get.toNamed(AppRoutes.profile);
                  },
                  icon: Icon(
                    Icons.person_outline_rounded,
                    color: homeController.currentIndex.value == 4
                        ? Colors.white
                        : AppColors.grey,
                    size: width * 0.065,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
