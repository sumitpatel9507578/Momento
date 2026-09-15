import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../repositories/user_repository.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class FollowersScreen extends StatelessWidget {
  FollowersScreen({super.key});

  final UserRepository repository = UserRepository();

  @override
  Widget build(BuildContext context) {
    final String? effectiveTag = Get.arguments?.toString() ?? 'me';
    final ProfileController controller = Get.find<ProfileController>(tag: effectiveTag);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Followers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.users.isEmpty) {
          return const Center(
            child: Text(
              'No followers found',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        final followers = controller.users;

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.015,
          ),
          itemCount: followers.length,
          separatorBuilder: (context, index) =>
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          itemBuilder: (context, index) {
            final user = followers[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: size.width * 0.065,
                    backgroundImage: user.profileImage.isNotEmpty
                        ? NetworkImage(
                            ApiConstants.getFullUrl(user.profileImage),
                          )
                        : null,
                    child: user.profileImage.isEmpty
                        ? const Icon(Icons.person, color: Colors.white24)
                        : null,
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
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => repository.followUser(user.uid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Follow',
                        style: TextStyle(
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
