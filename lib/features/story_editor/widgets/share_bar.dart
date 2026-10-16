import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/story_editor_controller.dart';

class ShareBar extends GetView<StoryEditorController> {
  const ShareBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      color: Colors.black.withValues(alpha: 0.6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Your Stories Pill
                  Obx(
                    () => GestureDetector(
                      onTap: () => controller.isYourStory.value =
                          !controller.isYourStory.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: controller.isYourStory.value
                              ? Colors.purple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: controller.isYourStory.value
                                ? Colors.purple
                                : Colors.white54,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.person, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Your Story',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close Friends Pill
                  Obx(
                    () => GestureDetector(
                      onTap: () => controller.isCloseFriends.value =
                          !controller.isCloseFriends.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: controller.isCloseFriends.value
                              ? const Color(0xFF2ED573)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: controller.isCloseFriends.value
                                ? const Color(0xFF2ED573)
                                : Colors.white54,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: controller.isCloseFriends.value
                                  ? Colors.white
                                  : const Color(0xFF2ED573),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Close Friends',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Next / Share Round Button
          GestureDetector(
            onTap: () => controller.uploadStory(),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
