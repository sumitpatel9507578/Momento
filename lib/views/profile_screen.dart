import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/profile_controller.dart';

import '../routes/app_routes.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/post_card.dart';
import '../widgets/report_bottom_sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/verification_badge.dart';

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
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.username.isNotEmpty
                          ? '@${user.username}'
                          : 'Profile',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    VerificationBadge(isVerified: user.isVerified, size: 16),
                  ],
                ),
                actions: [
                  if (isMe)
                    IconButton(
                      tooltip: 'Saved Items',
                      onPressed: () => Get.toNamed(AppRoutes.saved),
                      icon: const Icon(
                        Icons.bookmark_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                  if (!isMe)
                    IconButton(
                      onPressed: () => ReportBottomSheet.show(
                        context: context,
                        targetId: user.uid,
                        targetType: 'user',
                        targetTitle: user.username,
                      ),
                      icon: const Icon(
                        Icons.flag_outlined,
                        color: Colors.white,
                      ),
                    ),
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
                          GestureDetector(
                            onTap: () => _showFullProfileImageDialog(
                              context,
                              user.profileImage,
                              user.username,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: OnlineAvatar(
                                userId: user.uid,
                                imageUrl: user.profileImage,
                                radius: 38,
                                backgroundColor: AppColors.surface,
                              ),
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

                      // Tab Selector Bar (Posts / Reels / Saved)
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
                          if (isMe)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Get.toNamed(AppRoutes.saved),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.bookmark_outline_rounded,
                                    color: Colors.white38,
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
                _buildPostsGrid(controller, isMe: isMe)
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

  Widget _buildPostsGrid(ProfileController controller, {required bool isMe}) {
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
          onLongPress: () {
            if (isMe) {
              PostCard.showPostOptionsBottomSheet(
                context,
                post,
                onDelete: () async {
                  await controller.deletePost(post.postId);
                },
                onUpdateCaption: (newCaption) async {
                  await controller.updatePostCaption(post.postId, newCaption);
                },
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
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
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${post.likesCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${post.commentsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
                right: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${reel.likesCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${reel.commentsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  void _showFullProfileImageDialog(
    BuildContext context,
    String imageUrl,
    String username,
  ) {
    if (imageUrl.isEmpty) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GestureDetector(
          onTap: () => Get.back(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Image.network(
                      ApiConstants.getFullUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white54,
                          size: 100,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (username.isNotEmpty)
                Text(
                  '@$username',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
