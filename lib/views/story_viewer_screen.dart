import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/chat_controller.dart';
import 'package:momento/controllers/story_controller.dart';
import 'package:momento/models/story_model.dart';

import '../services/api_service.dart';
import 'package:momento/services/jamendo_service.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/user_avatar.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({super.key});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final StoryController controller = Get.find<StoryController>();
  final TextEditingController _replyController = TextEditingController();
  final AudioPlayer _storyAudioPlayer = AudioPlayer();
  final currentUserId = ''.obs;
  Worker? _storyIndexWorker;
  Worker? _userIndexWorker;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    controller.progress.value = 0.0;
    controller.startTimer();

    _storyIndexWorker = ever(controller.currentStoryIndex, (_) {
      _playStoryAudio();
    });
    _userIndexWorker = ever(controller.currentUserStoriesIndex, (_) {
      _playStoryAudio();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playStoryAudio();
    });
  }

  Future<void> _loadCurrentUserId() async {
    final uid = await Get.find<ApiService>().getUserId();
    currentUserId.value = uid ?? '';
  }

  Future<void> _playStoryAudio() async {
    try {
      await _storyAudioPlayer.stop();
      if (controller.userStories.isEmpty) return;
      final groupIdx = controller.currentUserStoriesIndex.value;
      if (groupIdx < 0 || groupIdx >= controller.userStories.length) return;
      final group = controller.userStories[groupIdx];
      final storyIdx = controller.currentStoryIndex.value;
      if (storyIdx < 0 || storyIdx >= group.stories.length) return;

      final story = group.stories[storyIdx];
      debugPrint(
        'STORY VIEWER AUDIO -> url: "${story.audioUrl}" | title: "${story.songTitle}"',
      );

      String audioToPlay = story.audioUrl;

      // Fallback: If audioUrl is empty, search Jamendo for story.songTitle
      if (audioToPlay.isEmpty && story.songTitle.isNotEmpty) {
        try {
          final query = story.songTitle
              .replaceFirst(RegExp(r'•.*$'), '')
              .trim();
          final results = await JamendoService().searchSongs(query);
          if (results.isNotEmpty && results.first.audioUrl.isNotEmpty) {
            audioToPlay = results.first.audioUrl;
          }
        } catch (_) {}
      }

      if (audioToPlay.isNotEmpty) {
        await _storyAudioPlayer.play(UrlSource(audioToPlay));
      }
    } catch (e) {
      debugPrint('Story AudioPlayer Error: $e');
    }
  }

  @override
  void dispose() {
    _storyIndexWorker?.dispose();
    _userIndexWorker?.dispose();
    _storyAudioPlayer.stop();
    _storyAudioPlayer.dispose();
    _replyController.dispose();
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
          try {
            _storyAudioPlayer.pause();
          } catch (_) {}
        },
        onLongPressEnd: (_) {
          controller.resumeStory();
          try {
            _storyAudioPlayer.resume();
          } catch (_) {}
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
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
                                  ],
                                ),
                                if (story.songTitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          story.songTitle,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (story.userId == currentUserId.value)
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              color: AppColors.surface,
                              onSelected: (val) {
                                if (val == 'delete') {
                                  _confirmDeleteStory(context, story.storyId);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Delete Story',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

            // Bottom Action Bar (Viewers list for own story OR Reply + Like button for others' stories)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              left: 16,
              right: 16,
              child: Obx(() {
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
                final isMe = story.userId == currentUserId.value;

                if (isMe) {
                  final filteredViewers = story.viewers.where((v) {
                    final vId = (v['id'] ?? v['userId'] ?? v['user_id'] ?? '')
                        .toString();
                    return vId.isNotEmpty && vId != currentUserId.value;
                  }).toList();

                  final viewsCount = filteredViewers.isNotEmpty
                      ? filteredViewers.length
                      : (story.viewsCount > 0
                            ? (story.viewsCount - 1).clamp(0, 99999)
                            : 0);

                  return GestureDetector(
                    onTap: () {
                      controller.pauseStory();
                      _showViewersSheet(context, story);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.remove_red_eye_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            viewsCount > 0 ? 'Seen by $viewsCount' : 'Activity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: TextField(
                            controller: _replyController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Send message to ${userStoryGroup.username}...',
                              hintStyle: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (text) =>
                                _sendStoryReply(text, story, userStoryGroup),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          controller.toggleLikeStory(story.storyId);
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            story.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: story.isLiked
                                ? Colors.redAccent
                                : Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewersSheet(BuildContext context, StoryModel story) async {
    final viewersList = await controller.fetchStoryViewers(story.storyId);
    final rawViewers = viewersList.isNotEmpty ? viewersList : story.viewers;

    final displayViewers = rawViewers.where((v) {
      final vId = (v['id'] ?? v['userId'] ?? v['user_id'] ?? '').toString();
      return vId.isNotEmpty && vId != currentUserId.value;
    }).toList();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.remove_red_eye,
                    color: AppColors.purple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Story Viewers (${displayViewers.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: displayViewers.isEmpty
                    ? const Center(
                        child: Text(
                          'No viewers yet',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 13.5,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: displayViewers.length,
                        itemBuilder: (context, index) {
                          final v = displayViewers[index];
                          final name = v['name'] ?? v['username'] ?? 'User';
                          final handle = v['username'] ?? '';
                          final img = v['profileImage'] ?? '';
                          final liked = v['liked'] == true;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: UserAvatar(
                              userId: v['id'] ?? '',
                              imageUrl: img,
                              radius: 20,
                              backgroundColor: AppColors.darkGrey,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: handle.isNotEmpty
                                ? Text(
                                    '@$handle',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing: liked
                                ? const Icon(
                                    Icons.favorite,
                                    color: Colors.redAccent,
                                    size: 18,
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );

    controller.resumeStory();
  }

  void _sendStoryReply(String text, StoryModel story, UserStories group) async {
    final msg = text.trim();
    if (msg.isEmpty) return;

    _replyController.clear();
    FocusScope.of(context).unfocus();

    if (Get.isRegistered<ChatController>()) {
      final chatCtrl = Get.find<ChatController>();
      await chatCtrl.sendMessage(group.userId, 'Replied to story: $msg');
      Get.snackbar(
        'Sent',
        'Reply sent to ${group.username}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _confirmDeleteStory(BuildContext context, String storyId) {
    controller.pauseStory();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Story?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this story? This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.resumeStory();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deleteStory(storyId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
