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
      child: Obx(() {
        final isReel = controller.isReelMode.value;

        return Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Mode Toggle Pill (Your Reel / Your Story)
                    GestureDetector(
                      onTap: () {
                        controller.isReelMode.value = !controller.isReelMode.value;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isReel ? Colors.purple : Colors.blueAccent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isReel ? Icons.movie_creation : Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isReel ? 'Your Reel' : 'Your Story',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    if (!isReel)
                      // Close Friends Pill (Only for Story)
                      GestureDetector(
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
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Share Button
            GestureDetector(
              onTap: () => controller.uploadContent(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isReel ? Colors.purpleAccent : Colors.blueAccent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Text(
                      isReel ? 'Share Reel' : 'Share Story',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
