import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/widgets/glass_container.dart';
import 'package:momento/widgets/post_card.dart';
import 'package:momento/widgets/story_bar.dart';

import '../controllers/home_controller.dart';
import '../controllers/network_controller.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient blobs could go here for Liquid Glass effect
          RefreshIndicator(
            onRefresh: homeController.refreshPosts,
            color: AppColors.purple,
            backgroundColor: AppColors.surface,
            edgeOffset: size.height * 0.1,
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
                  // Top Spacing for Glass App Bar
                  SliverToBoxAdapter(
                    child: SizedBox(height: size.height * 0.12),
                  ),

                  // Stories
                  const SliverToBoxAdapter(child: StoryBar()),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // Feed
                  Obx(() {
                    if (homeController.isLoading.value &&
                        homeController.posts.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.purple,
                          ),
                        ),
                      );
                    }

                    if (homeController.errorMessage.isNotEmpty &&
                        homeController.posts.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white24,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                homeController.errorMessage.value,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: homeController.loadPosts,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.purple,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (homeController.posts.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No posts found',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = homeController.posts[index];
                          return PostCard(
                            post: post,
                            onLike: () => homeController.toggleLike(index),
                            onSave: () => homeController.toggleSave(index),
                            onFollow: () => homeController.toggleFollow(index),
                            onComment: () {
                              // Simple comment sheet placeholder
                              Get.bottomSheet(
                                GlassContainer(
                                  height: size.height * 0.5,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(32),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Comments coming soon...',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              );
                            },
                            onMore: () {
                              Get.bottomSheet(
                                GlassContainer(
                                  height: size.height * 0.45,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(32),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 12),
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _buildMenuOption(
                                          Icons.report_gmailerrorred_rounded,
                                          'Report',
                                          Colors.redAccent,
                                        ),
                                        _buildMenuOption(
                                          Icons.block_flipped,
                                          'Block',
                                          Colors.redAccent,
                                        ),
                                        _buildMenuOption(
                                          Icons.visibility_off_outlined,
                                          'Not Interested',
                                          Colors.white,
                                        ),
                                        _buildMenuOption(
                                          Icons.notifications_off_outlined,
                                          'Mute',
                                          Colors.white,
                                        ),
                                        _buildMenuOption(
                                          Icons.link_rounded,
                                          'Copy Link',
                                          Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }, childCount: homeController.posts.length),
                      ),
                    );
                  }),

                  // Loading More Indicator
                  Obx(() {
                    if (homeController.isLoadingMore.value) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.purple,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    );
                  }),
                ],
              ),
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

  Widget _buildMenuOption(IconData icon, String title, Color color) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        onTap: () => Get.back(),
      ),
    );
  }
}
