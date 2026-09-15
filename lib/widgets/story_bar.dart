import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/profile_controller.dart';
import '../controllers/story_controller.dart';
import '../widgets/glass_container.dart';
import 'story_item.dart';

class StoryBar extends StatelessWidget {
  const StoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final StoryController storyController = Get.find<StoryController>();

    return SizedBox(
      height: 110,
      child: Obx(() {
        if (storyController.isLoading.value &&
            storyController.stories.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: storyController.stories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Obx(() {
                final user = Get.find<ProfileController>(tag: 'me').currentUser.value;
                return StoryItem(
                  isCurrentUser: true,
                  profileImage: user?.profileImage,
                  onTap: () =>
                      _showCreateStoryOptions(context, storyController),
                );
              });
            }

            final story = storyController.stories[index - 1];
            return StoryItem(
              story: story,
              onTap: () {
                storyController.currentStoryIndex.value = index - 1;
                Get.toNamed('/story');
              },
            );
          },
        );
      }),
    );
  }

  void _showCreateStoryOptions(
    BuildContext context,
    StoryController controller,
  ) {
    Get.bottomSheet(
      GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Create Story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                controller.pickStoryImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Colors.white,
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                controller.pickStoryImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
