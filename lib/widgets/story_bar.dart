import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/profile_controller.dart';
import '../controllers/story_controller.dart';
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
                final user = Get.find<ProfileController>(
                  tag: 'me',
                ).currentUser.value;
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
      Container(
        color: Colors.grey[900],
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                controller.pickStoryImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                controller.pickStoryImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
