import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../repositories/user_repository.dart';
import '../routes/app_routes.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/user_avatar.dart';

class FollowingScreen extends StatelessWidget {
  FollowingScreen({super.key});

  final UserRepository repository = UserRepository();

  @override
  Widget build(BuildContext context) {
    final String? effectiveTag = Get.arguments?.toString() ?? 'me';
    final ProfileController controller = Get.find<ProfileController>(
      tag: effectiveTag,
    );
    final size = MediaQuery.sizeOf(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshProfile();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Following',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        final following = controller.following;

        if (following.isEmpty) {
          return const Center(
            child: Text(
              'You are not following anyone yet',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.015,
          ),
          itemCount: following.length,
          separatorBuilder: (context, index) =>
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          itemBuilder: (context, index) {
            final user = following[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  OnlineAvatar(
                    userId: user.uid,
                    imageUrl: user.profileImage,
                    radius: size.width * 0.065,
                    onTap: () =>
                        Get.toNamed(AppRoutes.profile, arguments: user.uid),
                  ),

                  SizedBox(width: size.width * 0.035),

                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Get.toNamed(AppRoutes.profile, arguments: user.uid),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${user.username}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () async {
                        final success = await repository.followUser(user.uid);
                        if (success == true) {
                          await controller.refreshProfile();
                          Get.snackbar(
                            'Success',
                            user.isFollowing
                                ? 'Unfollowed user'
                                : 'Followed user',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 1),
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            'Could not update follow status',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        user.isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
