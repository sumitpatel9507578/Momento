import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../routes/app_routes.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  final String? tag;
  const ProfileScreen({super.key, this.tag});

  @override
  Widget build(BuildContext context) {
    // If an ID is passed, we use a NEW controller instance for that user,
    // but GetX by default shares the same instance if we use find.
    // For now, let's use the arguments to trigger the correct data load.
    final ProfileController controller =
        Get.isRegistered<ProfileController>(tag: tag ?? 'me')
        ? Get.find<ProfileController>(tag: tag ?? 'me')
        : (Get.isRegistered<ProfileController>()
              ? Get.find<ProfileController>()
              : Get.put(ProfileController()));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.currentUser.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        final user = controller.currentUser.value;

        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No profile found',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                  ),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          );
        }

        final isMe = Get.arguments == null;

        return RefreshIndicator(
          onRefresh: controller.refreshProfile,
          color: AppColors.purple,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: AppColors.background,
                leading: isMe
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Get.back(),
                      ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMe)
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Colors.white,
                      ),
                    if (isMe) const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe)
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.white,
                      ),
                  ],
                ),
                actions: [
                  if (isMe)
                    IconButton(
                      onPressed: () => Get.toNamed(AppRoutes.create),
                      icon: const Icon(
                        Icons.add_box_outlined,
                        color: Colors.white,
                      ),
                    ),
                  IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.settings),
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Hero(
                            tag: 'profile_${user.uid}',
                            child: Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: CircleAvatar(
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
                                        color: Colors.white54,
                                        size: 36,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(user.postsCount, 'Posts'),
                                _buildStatItem(
                                  user.followersCount,
                                  'Followers',
                                ),
                                _buildStatItem(
                                  user.followingCount,
                                  'Following',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.bio.isEmpty
                            ? 'Every moment has a story ✨'
                            : user.bio,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProfileButton(
                              isMe
                                  ? 'Edit profile'
                                  : (user.isFollowing ? 'Unfollow' : 'Follow'),
                              () {
                                if (isMe) {
                                  Get.toNamed(AppRoutes.editProfile);
                                } else {
                                  controller.toggleFollowUser(user.uid);
                                }
                              },
                              isPrimary: !isMe && !user.isFollowing,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildProfileButton('Share profile', () {}),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildTabItem(controller, 0, Icons.grid_on_rounded),
                          _buildTabItem(
                            controller,
                            1,
                            Icons.video_library_outlined,
                          ),
                          _buildTabItem(
                            controller,
                            2,
                            Icons.person_pin_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Grid Content
              SliverPadding(
                padding: const EdgeInsets.all(2),
                sliver: _buildGridContent(controller),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileButton(
    String text,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.purple
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildTabItem(ProfileController controller, int index, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeProfileTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: controller.selectedProfileTab.value == index
                    ? Colors.white
                    : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: controller.selectedProfileTab.value == index
                ? Colors.white
                : Colors.white38,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent(ProfileController controller) {
    final images = controller.currentTabImages;

    if (images.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 100),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.camera_alt_outlined, color: Colors.white, size: 60),
                SizedBox(height: 12),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Image.network(
          ApiConstants.getFullUrl(images[index]),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.surface,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white54,
            ),
          ),
        );
      }, childCount: images.length),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
    );
  }
}
