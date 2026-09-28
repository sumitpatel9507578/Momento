import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../routes/app_routes.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.tag});

  final String? tag;

  @override
  Widget build(BuildContext context) {
    String effectiveTag = 'me';
    if (tag != null && tag!.isNotEmpty) {
      effectiveTag = tag!;
    } else {
      final extracted = ProfileController.extractUserId(Get.arguments);
      if (extracted != null && extracted.isNotEmpty) {
        effectiveTag = extracted;
      }
    }

    final controller = Get.isRegistered<ProfileController>(tag: effectiveTag)
        ? Get.find<ProfileController>(tag: effectiveTag)
        : Get.put(ProfileController(), tag: effectiveTag);

    if (controller.currentUser.value == null && !controller.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadProfile(userId: effectiveTag);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final user = controller.currentUser.value;

        // Loading state
        if (controller.isLoading.value && user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        // Error / Null state
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 72,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value.isNotEmpty
                        ? controller.errorMessage.value
                        : 'Profile not found',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => controller.loadProfile(forceRefresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if viewing own profile
        final myProfileController =
            Get.isRegistered<ProfileController>(tag: 'me')
            ? Get.find<ProfileController>(tag: 'me')
            : null;
        final myUid = myProfileController?.currentUser.value?.uid;

        final isMe =
            effectiveTag == 'me' ||
            (myUid != null &&
                myUid.isNotEmpty &&
                user.uid.isNotEmpty &&
                user.uid == myUid);

        return RefreshIndicator(
          color: AppColors.purple,
          backgroundColor: AppColors.surface,
          onRefresh: controller.refreshProfile,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                title: Text(
                  user.username.isNotEmpty ? '@${user.username}' : 'Profile',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.settings),
                    icon: const Icon(Icons.menu, color: Colors.white),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar and Stats Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: AppColors.surface,
                              backgroundImage: user.profileImage.isNotEmpty
                                  ? NetworkImage(
                                      ApiConstants.getFullUrl(
                                        user.profileImage,
                                      ),
                                    )
                                  : null,
                              child: user.profileImage.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white54,
                                    )
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStat(
                                  'Posts',
                                  user.postsCount,
                                  onTap: () => controller.changeProfileTab(0),
                                ),
                                _buildStat(
                                  'Followers',
                                  controller.followers.length >
                                          user.followersCount
                                      ? controller.followers.length
                                      : user.followersCount,
                                  onTap: () => Get.toNamed(
                                    AppRoutes.followers,
                                    arguments: effectiveTag,
                                  ),
                                ),
                                _buildStat(
                                  'Following',
                                  controller.following.length >
                                          user.followingCount
                                      ? controller.following.length
                                      : user.followingCount,
                                  onTap: () => Get.toNamed(
                                    AppRoutes.following,
                                    arguments: effectiveTag,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Full Name
                      if (user.name.isNotEmpty)
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                      // Bio
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.bio,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: isMe
                                ? OutlinedButton(
                                    onPressed: () =>
                                        Get.toNamed(AppRoutes.editProfile),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Edit Profile',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () =>
                                        controller.toggleFollowUser(user.uid),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: user.isFollowing
                                          ? Colors.white12
                                          : AppColors.purple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      user.isFollowing ? 'Unfollow' : 'Follow',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: isMe
                                ? OutlinedButton(
                                    onPressed: () {
                                      Get.snackbar(
                                        'Profile',
                                        'Profile link copied to clipboard!',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.surface,
                                        colorText: Colors.white,
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Share Profile',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: () {
                                      Get.toNamed(
                                        AppRoutes.chat,
                                        arguments: user,
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Message',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Tab Selector Bar (Posts / Reels)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.changeProfileTab(0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color:
                                          controller.selectedProfileTab.value ==
                                              0
                                          ? AppColors.purple
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  Icons.grid_on_rounded,
                                  color:
                                      controller.selectedProfileTab.value == 0
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.changeProfileTab(1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color:
                                          controller.selectedProfileTab.value ==
                                              1
                                          ? AppColors.purple
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  Icons.movie_outlined,
                                  color:
                                      controller.selectedProfileTab.value == 1
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Posts or Reels Grid View
              if (controller.selectedProfileTab.value == 0)
                _buildPostsGrid(controller)
              else
                _buildReelsGrid(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStat(String label, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(ProfileController controller) {
    final posts = controller.userPosts;

    if (posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: Colors.white24,
              ),
              SizedBox(height: 8),
              Text(
                'No posts yet',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final post = posts[index];
        final fullUrl = ApiConstants.getFullUrl(post.mediaUrl);

        return GestureDetector(
          onTap: () => Get.toNamed('/post-details', arguments: post),
          child: Image.network(
            fullUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.surface,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white24,
                ),
              );
            },
          ),
        );
      }, childCount: posts.length),
    );
  }

  Widget _buildReelsGrid(ProfileController controller) {
    final reels = controller.userReels;

    if (reels.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(
                Icons.video_collection_outlined,
                size: 48,
                color: Colors.white24,
              ),
              SizedBox(height: 8),
              Text(
                'No reels yet',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final reel = reels[index];
        final imageUrl = ApiConstants.getFullUrl(
          reel.thumbnail.isNotEmpty ? reel.thumbnail : reel.videoUrl,
        );

        return GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.reels, arguments: reel),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.videocam_outlined,
                      color: Colors.white24,
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 6,
                left: 6,
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      '${reel.likesCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }, childCount: reels.length),
    );
  }
}
