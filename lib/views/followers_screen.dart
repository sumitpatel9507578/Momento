import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../utils/app_colors.dart';

class FollowersScreen extends StatelessWidget {
  FollowersScreen({super.key});

  final ProfileController controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Followers'),
      ),
      body: Obx(() {
        if (controller.users.isEmpty) {
          return const Center(
            child: Text(
              'No followers found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final followers = controller.followers;

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.015,
          ),
          itemCount: followers.length,
          separatorBuilder: (_, __) =>
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          itemBuilder: (context, index) {
            final user = followers[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: size.width * 0.065,
                    backgroundImage: NetworkImage(user.profileImage),
                  ),

                  SizedBox(width: size.width * 0.035),

                  Expanded(
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
                          style: const TextStyle(color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: size.height * 0.05,
                    child: Obx(() {
                      final isFollowing = controller.isFollowing(user.uid);

                      return SizedBox(
                        height: size.height * 0.05,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.toggleFollow(user.uid);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? AppColors.surface
                                : AppColors.purple,
                            foregroundColor: Colors.white,
                            side: isFollowing
                                ? BorderSide(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  )
                                : BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(isFollowing ? 'Following' : 'Follow'),
                        ),
                      );
                    }),
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
