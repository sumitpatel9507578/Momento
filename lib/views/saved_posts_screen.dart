import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../utils/app_colors.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Saved posts are specific to the current user
    final ProfileController profileController = Get.find<ProfileController>(
      tag: 'me',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Saved',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (profileController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                color: Colors.white24,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                'No saved items yet',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ],
          ),
        );
      }),
    );
  }
}
