import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.refreshUsers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final user = controller.currentUser.value;

        if (user == null) {
          return const Center(
            child: Text(
              'No profile found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshUsers,
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
                title: Text(
                  '@${user.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05,
                    vertical: size.height * 0.015,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.01),

                      Hero(
                        tag: 'profile_${user.uid}',
                        child: Container(
                          width: size.width * 0.28,
                          height: size.width * 0.28,
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: CircleAvatar(
                            backgroundColor: AppColors.surface,
                            backgroundImage: NetworkImage(user.profileImage),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.018),

                      Text(
                        user.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.06,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      SizedBox(height: size.height * 0.005),

                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: size.width * 0.035,
                        ),
                      ),

                      SizedBox(height: size.height * 0.012),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.08,
                        ),
                        child: Text(
                          user.bio.isEmpty
                              ? 'Every moment has a story ✨'
                              : user.bio,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: size.width * 0.035,
                            height: 1.4,
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.025),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat(
                            context,
                            value: user.postsCount,
                            label: 'Posts',
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.toNamed(AppRoutes.followers);
                            },
                            child: _buildStat(
                              context,
                              value: user.followersCount,
                              label: 'Followers',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.toNamed(AppRoutes.following);
                            },
                            child: _buildStat(
                              context,
                              value: user.followingCount,
                              label: 'Following',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: size.height * 0.025),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Edit Profile next.
                              },
                              child: GlassContainer(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                child: const Center(
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: size.width * 0.025),

                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                height: size.height * 0.055,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Share Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: size.height * 0.025),

                      Obx(
                        () => Row(
                          children: [
                            _profileTab(
                              context,
                              index: 0,
                              icon: Icons.grid_on_rounded,
                            ),
                            _profileTab(
                              context,
                              index: 1,
                              icon: Icons.video_library_outlined,
                            ),
                            _profileTab(
                              context,
                              index: 2,
                              icon: Icons.bookmark_border_rounded,
                            ),
                            _profileTab(
                              context,
                              index: 3,
                              icon: Icons.person_pin_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(2),
                sliver: Obx(() {
                  final images = controller.currentTabImages;

                  if (images.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No content yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white54,
                            ),
                          );
                        },
                      );
                    }, childCount: images.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                  );
                }),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required int value,
    required String label,
  }) {
    final width = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.045,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppColors.grey, fontSize: width * 0.03),
        ),
      ],
    );
  }

  Widget _profileTab(
    BuildContext context, {
    required int index,
    required IconData icon,
  }) {
    final size = MediaQuery.sizeOf(context);

    final isSelected = controller.selectedProfileTab.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.changeProfileTab(index);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.purple : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppColors.grey,
            size: size.width * 0.06,
          ),
        ),
      ),
    );
  }
}
