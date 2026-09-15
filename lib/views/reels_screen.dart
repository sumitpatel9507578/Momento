import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../controllers/reel_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/comment_bottom_sheet.dart';
import '../widgets/share_bottom_sheet.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ReelController controller = Get.find<ReelController>();
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isLoading.value && controller.reels.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.reels.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white54,
                  size: 50,
                ),
                const SizedBox(height: 15),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: controller.getReels,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.reels.isEmpty) {
          return const Center(
            child: Text(
              'No reels found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: controller.reels.length,
          onPageChanged: (index) {
            controller.playVideo(index);
            if (index >= controller.reels.length - 3) {
              controller.loadMore();
            }
          },
          itemBuilder: (context, index) {
            final reel = controller.reels[index];
            final videoController = controller.getVideoController(index);

            return GestureDetector(
              onTap: () {
                controller.togglePlayPause(index);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (videoController != null &&
                      videoController.value.isInitialized)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: videoController.value.size.width,
                        height: videoController.value.size.height,
                        child: VideoPlayer(videoController),
                      ),
                    )
                  else if (controller.failedInitializations.contains(reel.id))
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white54,
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Video unavailable",
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () => controller.retryVideo(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.purple,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Tap to Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),

                  // Header info
                  Positioned(
                    top: height * 0.05,
                    left: width * 0.04,
                    child: const Text(
                      'Reels',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Bottom info
                  Positioned(
                    left: width * 0.04,
                    right: width * 0.20,
                    bottom: height * 0.04,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: reel.thumbnail.isNotEmpty
                                  ? NetworkImage(
                                      ApiConstants.getFullUrl(reel.thumbnail),
                                    )
                                  : null,
                              child: reel.thumbnail.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '@${reel.creatorName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          reel.caption.isEmpty
                              ? 'Enjoy this amazing reel ✨ #Momento'
                              : reel.caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        if (reel.songId.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.music_note,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Original Audio - ${reel.songId}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Right side buttons
                  Positioned(
                    right: width * 0.03,
                    bottom: height * 0.08,
                    child: Column(
                      children: [
                        Obx(() {
                          final currentReel = controller.reels[index];
                          return _buildActionButton(
                            icon: currentReel.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: '${currentReel.likesCount}',
                            color: currentReel.isLiked
                                ? Colors.redAccent
                                : Colors.white,
                            onTap: () => controller.toggleLike(index),
                          );
                        }),
                        const SizedBox(height: 18),
                        Obx(() {
                          final currentReel = controller.reels[index];
                          return _buildActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '${currentReel.commentsCount}',
                            onTap: () => Get.bottomSheet(
                              CommentBottomSheet(
                                id: currentReel.id,
                                isReel: true,
                              ),
                              isScrollControlled: true,
                            ),
                          );
                        }),
                        const SizedBox(height: 18),
                        _buildActionButton(
                          icon: Icons.send_outlined,
                          label: '',
                          onTap: () =>
                              Get.bottomSheet(const ShareBottomSheet()),
                        ),
                        const SizedBox(height: 18),
                        Obx(
                          () => _buildActionButton(
                            icon: controller.isSaved(reel.id)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            label: '',
                            onTap: () => controller.toggleSave(index),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Icon(Icons.more_vert, color: Colors.white),
                      ],
                    ),
                  ),

                  // Video progress
                  if (videoController != null &&
                      videoController.value.isInitialized)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        videoController,
                        allowScrubbing: false,
                        colors: const VideoProgressColors(
                          playedColor: AppColors.purple,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white12,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
