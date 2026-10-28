import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/profile_controller.dart';
import '../controllers/story_controller.dart';
import '../models/story_model.dart';
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
            storyController.userStories.isEmpty) {
          return const SizedBox.shrink();
        }

        final profileCtrl = Get.find<ProfileController>(tag: 'me');
        final currentUserId = profileCtrl.currentUser.value?.uid ?? '';
        final profileImage = profileCtrl.currentUser.value?.profileImage;

        UserStories? myStories;
        final otherUserStories = <UserStories>[];

        for (final us in storyController.userStories) {
          if (us.userId == currentUserId) {
            myStories = us;
          } else {
            otherUserStories.add(us);
          }
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: otherUserStories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return StoryItem(
                isCurrentUser: true,
                userStories: myStories,
                profileImage: profileImage,
                onAddTap: () =>
                    _showCreateStoryOptions(context, storyController),
                onTap: () {
                  if (myStories != null && myStories.stories.isNotEmpty) {
                    final myIndex = storyController.userStories.indexWhere(
                      (us) => us.userId == currentUserId,
                    );
                    if (myIndex != -1) {
                      storyController.currentUserStoriesIndex.value = myIndex;
                      storyController.currentStoryIndex.value =
                          myStories.firstUnviewedIndex;
                      Get.toNamed('/story');
                    }
                  } else {
                    _showCreateStoryOptions(context, storyController);
                  }
                },
              );
            }

            final us = otherUserStories[index - 1];
            return StoryItem(
              userStories: us,
              onTap: () {
                final realIndex = storyController.userStories.indexWhere(
                  (item) => item.userId == us.userId,
                );
                if (realIndex != -1) {
                  storyController.currentUserStoriesIndex.value = realIndex;
                  storyController.currentStoryIndex.value =
                      us.firstUnviewedIndex;
                  Get.toNamed('/story');
                }
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
