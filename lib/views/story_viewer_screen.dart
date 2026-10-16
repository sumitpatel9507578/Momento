import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/story_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({super.key});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final StoryController controller = Get.find<StoryController>();

  @override
  void initState() {
    super.initState();
    controller.progress.value = 0.0;
    controller.startTimer();
  }

  @override
  void dispose() {
    controller.stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) {
          controller.pauseStory();
        },
        onLongPressEnd: (_) {
          controller.resumeStory();
        },
        onTapDown: (details) {
          final x = details.globalPosition.dx;
          if (x < size.width / 3) {
            controller.previousStory();
          } else if (x > size.width * 2 / 3) {
            controller.nextStory();
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
            Get.back();
          }
        },
        child: Stack(
          children: [
            // Media Content
            Obx(() {
              if (controller.userStories.isEmpty) {
                return const SizedBox.shrink();
              }
              final groupIndex = controller.currentUserStoriesIndex.value;
              if (groupIndex < 0 ||
                  groupIndex >= controller.userStories.length) {
                return const SizedBox.shrink();
              }
              final userStoryGroup = controller.userStories[groupIndex];
              final storyIndex = controller.currentStoryIndex.value;
              if (storyIndex < 0 ||
                  storyIndex >= userStoryGroup.stories.length) {
                return const SizedBox.shrink();
              }

              final story = userStoryGroup.stories[storyIndex];
              final isLocal = story.mediaUrl.startsWith('/');

              return Center(
                child: isLocal
                    ? Image.file(
                        File(story.mediaUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Image.network(
                        ApiConstants.getFullUrl(story.mediaUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.purple,
                            ),
                          );
                        },
                      ),
              );
            }),

            // Top Progress Bars & User Info
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Obx(() {
                      if (controller.userStories.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final groupIndex =
                          controller.currentUserStoriesIndex.value;
                      if (groupIndex < 0 ||
                          groupIndex >= controller.userStories.length) {
                        return const SizedBox.shrink();
                      }
                      final userStoryGroup = controller.userStories[groupIndex];

                      return Row(
                        children: List.generate(userStoryGroup.stories.length, (
                          index,
                        ) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: LinearProgressIndicator(
                                value:
                                    index < controller.currentStoryIndex.value
                                    ? 1.0
                                    : (index ==
                                              controller.currentStoryIndex.value
                                          ? controller.progress.value
                                          : 0.0),
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 2,
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Obx(() {
                      if (controller.userStories.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final groupIndex =
                          controller.currentUserStoriesIndex.value;
                      if (groupIndex < 0 ||
                          groupIndex >= controller.userStories.length) {
                        return const SizedBox.shrink();
                      }
                      final userStoryGroup = controller.userStories[groupIndex];
                      final storyIndex = controller.currentStoryIndex.value;
                      if (storyIndex < 0 ||
                          storyIndex >= userStoryGroup.stories.length) {
                        return const SizedBox.shrink();
                      }

                      final story = userStoryGroup.stories[storyIndex];
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                userStoryGroup.profileImage.isNotEmpty
                                ? NetworkImage(
                                    ApiConstants.getFullUrl(
                                      userStoryGroup.profileImage,
                                    ),
                                  )
                                : null,
                            child: userStoryGroup.profileImage.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.white38,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            userStoryGroup.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(story.timestamp),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
