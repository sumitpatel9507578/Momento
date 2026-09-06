import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
              return StoryItem(isCurrentUser: true, onTap: () {});
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
}
