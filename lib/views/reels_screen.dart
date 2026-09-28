import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reel_controller.dart';
import 'package:video_player/video_player.dart';

import '../controllers/profile_controller.dart';
import '../models/reel_model.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/share_bottom_sheet.dart';

class ReelsScreen extends GetView<ReelController> {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isLoading.value && controller.reels.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (controller.reels.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.refreshReels,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.movie_creation_outlined,
                        color: Colors.white38,
                        size: 60,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No reels found',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: controller.refreshReels,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshReels,
          child: PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: controller.reels.length,
            onPageChanged: (index) {
              controller.playVideo(index);
              if (index >= controller.reels.length - 2) controller.loadMore();
            },
            itemBuilder: (context, index) {
              final reel = controller.reels[index];
              final videoController = controller.getVideoController(index);

              return Stack(
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
                  else
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),

                  // Bottom Gradient for text visibility
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black54],
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Content Overlay
                  Positioned(
                    left: 16,
                    bottom: 20,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Get.toNamed('/profile', arguments: reel.userId),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(
                                  ApiConstants.getFullUrl(reel.thumbnail),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                reel.creatorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reel.caption,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Right Sidebar Actions
                  Positioned(
                    right: 12,
                    bottom: 20,
                    child: Column(
                      children: [
                        _buildAction(
                          Icons.favorite,
                          '${reel.likesCount}',
                          () => controller.toggleLike(index),
                        ),
                        _buildAction(
                          Icons.comment,
                          '${reel.commentsCount}',
                          () {},
                        ),
                        _buildAction(
                          Icons.send,
                          '',
                          () => Get.bottomSheet(
                            ShareBottomSheet(contentUrl: reel.videoUrl),
                          ),
                        ),
                        _buildAction(
                          Icons.more_vert,
                          '',
                          () => showReelOptionsBottomSheet(
                            context,
                            reel,
                            controller,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 30),
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

void showReelOptionsBottomSheet(
  BuildContext context,
  ReelModel reel,
  ReelController controller,
) async {
  final apiService = Get.find<ApiService>();
  final currentUserId = await apiService.getUserId();
  final myProfile = Get.isRegistered<ProfileController>(tag: 'me')
      ? Get.find<ProfileController>(tag: 'me').currentUser.value
      : null;
  final myUid = currentUserId ?? myProfile?.uid ?? '';

  final bool isMyReel = myUid.isNotEmpty && reel.userId == myUid;

  Get.bottomSheet(
    Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Wrap(
        children: [
          if (isMyReel) ...[
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Delete Reel',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Get.back();
                _showDeleteReelConfirmation(context, reel, controller);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text(
              'Share Link',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Get.back();
              Get.snackbar('Share', 'Link copied to clipboard!');
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.white54),
            title: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
            onTap: () => Get.back(),
          ),
        ],
      ),
    ),
  );
}

void _showDeleteReelConfirmation(
  BuildContext context,
  ReelModel reel,
  ReelController controller,
) {
  Get.dialog(
    AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Delete Reel', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Are you sure you want to delete this reel? This action cannot be undone.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
            controller.deleteReel(reel.id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
