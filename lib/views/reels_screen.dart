import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/reel_controller.dart';
import 'package:momento/models/reel_model.dart';
import 'package:momento/utils/api_constants.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/comment_bottom_sheet.dart';
import 'package:momento/widgets/share_bottom_sheet.dart';
import 'package:momento/widgets/user_avatar.dart';
import 'package:momento/widgets/verification_badge.dart';
import 'package:video_player/video_player.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late final ReelController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ReelController>()
        ? Get.find<ReelController>()
        : Get.put(ReelController());
    controller.openFromArguments(Get.arguments);
  }

  @override
  void deactivate() {
    controller.pauseAllVideos();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        // Read videoVersion at top of Obx to track reactive dependency for video player
        final _ = controller.videoVersion.value;

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

        return PageView.builder(
          controller: controller.pageController,
          scrollDirection: Axis.vertical,
          itemCount: controller.reels.length,
          onPageChanged: (index) {
            controller.playVideo(index);
            if (index >= controller.reels.length - 2) controller.loadMore();
          },
          itemBuilder: (context, index) {
            final reel = controller.reels[index];
            return _ReelPageItem(
              key: ValueKey(reel.id),
              reel: reel,
              index: index,
              controller: controller,
            );
          },
        );
      }),
    );
  }
}

class _ReelPageItem extends StatefulWidget {
  final ReelModel reel;
  final int index;
  final ReelController controller;

  const _ReelPageItem({
    super.key,
    required this.reel,
    required this.index,
    required this.controller,
  });

  @override
  State<_ReelPageItem> createState() => _ReelPageItemState();
}

class _ReelPageItemState extends State<_ReelPageItem>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _showPlayIconNotifier = ValueNotifier<bool>(false);
  AnimationController? _animController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController!, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _showPlayIconNotifier.dispose();
    _animController?.dispose();
    super.dispose();
  }

  void _onTapVideo() {
    final videoController = widget.controller.getVideoController(widget.index);
    if (videoController == null || !videoController.value.isInitialized) return;

    final isCurrentlyPlaying = videoController.value.isPlaying;
    widget.controller.togglePlayPause(widget.index);

    if (isCurrentlyPlaying) {
      _showPlayIconNotifier.value = false;
    } else {
      _showPlayIconNotifier.value = true;
      _animController?.forward(from: 0.0).then((_) {
        if (mounted) {
          _showPlayIconNotifier.value = false;
        }
      });
    }
  }

  void _navigateToProfile() async {
    widget.controller.pauseAllVideos();
    await Get.toNamed('/profile', arguments: widget.reel.userId);
    widget.controller.resumeCurrentVideo();
  }

  void _openComments() async {
    widget.controller.pauseAllVideos();
    await Get.bottomSheet(
      CommentBottomSheet(id: widget.reel.id, isReel: true),
      isScrollControlled: true,
    );
    widget.controller.resumeCurrentVideo();
  }

  void _openShare() async {
    widget.controller.pauseAllVideos();
    await Get.bottomSheet(
      ShareBottomSheet(
        contentUrl: widget.reel.videoUrl,
        reelId: widget.reel.id,
      ),
    );
    widget.controller.resumeCurrentVideo();
  }

  void _openOptions() async {
    widget.controller.pauseAllVideos();
    await showReelOptionsBottomSheet(context, widget.reel, widget.controller);
    widget.controller.resumeCurrentVideo();
  }

  void _openRepostNoteSheet() async {
    widget.controller.pauseAllVideos();
    await showRepostSheet(
      context: context,
      isCurrentlyReposted: widget.reel.isReposted,
      currentNote: widget.reel.repostNote,
      onRepost: (note) =>
          widget.controller.toggleRepost(widget.index, note: note),
      onRemoveRepost: () =>
          widget.controller.toggleRepost(widget.index, removeNote: true),
    );
    widget.controller.resumeCurrentVideo();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final index = widget.index;
    final controller = widget.controller;
    final videoController = controller.getVideoController(index);
    final isInitialized =
        videoController != null && videoController.value.isInitialized;
    final isPlaying = isInitialized && videoController.value.isPlaying;

    return GestureDetector(
      onTap: _onTapVideo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: videoController.value.size.width,
                height: videoController.value.size.height,
                child: VideoPlayer(videoController),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // ValueListenableBuilder for Play/Pause icon overlays
          ValueListenableBuilder<bool>(
            valueListenable: _showPlayIconNotifier,
            builder: (context, showPlayIcon, child) {
              if (showPlayIcon) {
                return Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white70,
                        size: 70,
                      ),
                    ),
                  ),
                );
              }
              if (isInitialized && !isPlaying) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      color: Colors.white70,
                      size: 70,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Timeline Scrubber / Slider at the bottom
          if (isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                videoController,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
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

          // Instagram-Style Repost Note Bubble + Avatar Overlay
          if (reel.isReposted ||
              (reel.repostNote != null && reel.repostNote!.trim().isNotEmpty))
            Positioned(
              left: 16,
              bottom: 120,
              child: GestureDetector(
                onTap: _openRepostNoteSheet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Speech Bubble Note
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      constraints: const BoxConstraints(maxWidth: 200),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24, width: 0.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        (reel.repostNote != null &&
                                reel.repostNote!.trim().isNotEmpty)
                            ? reel.repostNote!
                            : 'Drop an emoji...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // User Avatar with Purple Repost Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.darkGrey,
                          backgroundImage: ApiConstants.getImageProvider(
                            reel.repostUserAvatar,
                          ),
                          child:
                              ApiConstants.getImageProvider(
                                    reel.repostUserAvatar,
                                  ) ==
                                  null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                  size: 20,
                                )
                              : null,
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              color: AppColors.purple,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.black, width: 1.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.repeat_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Content Overlay
          Positioned(
            left: 16,
            bottom: 36,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _navigateToProfile,
                  child: Row(
                    children: [
                      OnlineAvatar(
                        userId: reel.userId,
                        imageUrl: reel.thumbnail,
                        radius: 16,
                        backgroundColor: AppColors.darkGrey,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        reel.creatorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      VerificationBadge(isVerified: reel.isVerified, size: 15),
                    ],
                  ),
                ),
                if (reel.caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    reel.caption,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),

          // Right Sidebar Actions
          Positioned(
            right: 12,
            bottom: 36,
            child: Column(
              children: [
                _buildActionItem(
                  reel.isLiked ? Icons.favorite : Icons.favorite_border,
                  '${reel.likesCount}',
                  () => controller.toggleLike(index),
                  color: reel.isLiked ? Colors.redAccent : Colors.white,
                ),
                _buildActionItem(
                  Icons.chat_bubble_outline_rounded,
                  '${reel.commentsCount}',
                  _openComments,
                ),
                _buildActionItem(
                  Icons.repeat_rounded,
                  reel.repostsCount > 0 ? '${reel.repostsCount}' : '',
                  _openRepostNoteSheet,
                  color: reel.isReposted ? Colors.greenAccent : Colors.white,
                ),
                _buildActionItem(CupertinoIcons.paperplane, '', _openShare),
                // Mute button shown ONLY when video is paused
                if (!isPlaying)
                  Obx(
                    () => _buildActionItem(
                      controller.isMuted.value
                          ? Icons.volume_off
                          : Icons.volume_up,
                      '',
                      () => controller.toggleMute(index),
                    ),
                  ),
                _buildActionItem(Icons.more_vert, '', _openOptions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: color, size: 28),
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

Future<void> showRepostSheet({
  required BuildContext context,
  required bool isCurrentlyReposted,
  required String? currentNote,
  required Function(String note) onRepost,
  required VoidCallback onRemoveRepost,
}) async {
  final textController = TextEditingController(text: currentNote ?? '');
  final quickEmojis = ['😂', '🔥', '❤️', '💯', '🙌', '😮', '👏', '😍'];

  await Get.bottomSheet<void>(
    Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.repeat_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isCurrentlyReposted
                    ? 'Edit Repost Note'
                    : 'Repost with a Thought',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Add a thought or drop an emoji...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick Emojis
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickEmojis.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final emoji = quickEmojis[index];
                return GestureDetector(
                  onTap: () {
                    textController.text = '${textController.text}$emoji';
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (isCurrentlyReposted)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      onRemoveRepost();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isCurrentlyReposted) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final note = textController.text.trim();
                    Get.back();
                    onRepost(note);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isCurrentlyReposted ? 'Save Note' : 'Repost Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

Future<void> showReelOptionsBottomSheet(
  BuildContext context,
  ReelModel reel,
  ReelController controller,
) {
  return Get.bottomSheet<void>(
    Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text(
              'Share to...',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Get.back();
              Get.bottomSheet(
                ShareBottomSheet(contentUrl: reel.videoUrl, reelId: reel.id),
              );
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
