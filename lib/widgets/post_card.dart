import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/home_controller.dart';
import 'package:momento/controllers/profile_controller.dart';
import 'package:momento/models/post_model.dart';
import 'package:momento/routes/app_routes.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/utils/api_constants.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/views/reels_screen.dart';
import 'package:momento/widgets/comment_bottom_sheet.dart';
import 'package:momento/widgets/report_bottom_sheet.dart';
import 'package:momento/widgets/share_bottom_sheet.dart';
import 'package:momento/widgets/user_avatar.dart';
import 'package:momento/widgets/verification_badge.dart';
import 'package:video_player/video_player.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onFollow;
  final VoidCallback onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onMore;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
    required this.onFollow,
    required this.onComment,
    this.onRepost,
    this.onMore,
  });

  @override
  State<PostCard> createState() => _PostCardState();

  static void showPostOptionsBottomSheet(
    BuildContext context,
    PostModel post, {
    VoidCallback? onDelete,
    Function(String)? onUpdateCaption,
  }) async {
    final apiService = Get.find<ApiService>();
    final currentUserId = await apiService.getUserId();
    final myProfile = Get.isRegistered<ProfileController>(tag: 'me')
        ? Get.find<ProfileController>(tag: 'me').currentUser.value
        : null;
    final myUid = currentUserId ?? myProfile?.uid ?? '';

    final bool isMyPost = myUid.isNotEmpty && post.userId == myUid;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Wrap(
          children: [
            if (isMyPost) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Edit Caption',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Get.back();
                  _showEditCaptionDialog(context, post, onUpdateCaption);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Get.back();
                  _showDeleteConfirmationDialog(context, post, onDelete);
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
                Clipboard.setData(
                  ClipboardData(text: ApiConstants.getFullUrl(post.mediaUrl)),
                );
                Get.snackbar('Share', 'Post link copied to clipboard!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Colors.white),
              title: const Text(
                'Save / Download to Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.savePostReel, arguments: post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
              title: const Text(
                'Report Post',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Get.back();
                ReportBottomSheet.show(
                  context: context,
                  targetId: post.postId,
                  targetType: 'post',
                  targetTitle: post.caption,
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

  static void _showEditCaptionDialog(
    BuildContext context,
    PostModel post,
    Function(String)? onUpdateCaption,
  ) {
    final textController = TextEditingController(text: post.caption);
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Edit Caption',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new caption...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.purple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              final newCaption = textController.text.trim();
              if (onUpdateCaption != null) {
                onUpdateCaption(newCaption);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _showDeleteConfirmationDialog(
    BuildContext context,
    PostModel post,
    VoidCallback? onDelete,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              if (onDelete != null) {
                onDelete();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PostCardState extends State<PostCard> {
  final _showHeart = false.obs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Perfect Instagram Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                OnlineAvatar(
                  userId: widget.post.userId,
                  imageUrl: widget.post.profileImage,
                  radius: 17,
                  backgroundColor: AppColors.surface,
                  onTap: () =>
                      Get.toNamed('/profile', arguments: widget.post.userId),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        Get.toNamed('/profile', arguments: widget.post.userId),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.post.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        VerificationBadge(
                          isVerified: widget.post.isVerified,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      widget.onMore ??
                      () {
                        PostCard.showPostOptionsBottomSheet(
                          context,
                          widget.post,
                          onDelete: () {
                            if (Get.isRegistered<HomeController>()) {
                              Get.find<HomeController>().deletePost(
                                widget.post.postId,
                              );
                            } else if (Get.isRegistered<ProfileController>(
                              tag: 'me',
                            )) {
                              Get.find<ProfileController>(
                                tag: 'me',
                              ).deletePost(widget.post.postId);
                            }
                          },
                          onUpdateCaption: (newCaption) {
                            if (Get.isRegistered<HomeController>()) {
                              Get.find<HomeController>().updatePostCaption(
                                widget.post.postId,
                                newCaption,
                              );
                            } else if (Get.isRegistered<ProfileController>(
                              tag: 'me',
                            )) {
                              Get.find<ProfileController>(
                                tag: 'me',
                              ).updatePostCaption(
                                widget.post.postId,
                                newCaption,
                              );
                            }
                          },
                        );
                      },
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          if (widget.post.isReposted ||
              (widget.post.repostNote != null &&
                  widget.post.repostNote!.trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: GestureDetector(
                onTap: () {
                  if (Get.isRegistered<HomeController>()) {
                    final homeCtrl = Get.find<HomeController>();
                    final idx = homeCtrl.posts.indexWhere(
                      (p) => p.postId == widget.post.postId,
                    );
                    if (idx != -1) {
                      showRepostSheet(
                        context: context,
                        isCurrentlyReposted: widget.post.isReposted,
                        currentNote: widget.post.repostNote,
                        onRepost: (note) =>
                            homeCtrl.toggleRepost(idx, note: note),
                        onRemoveRepost: () =>
                            homeCtrl.toggleRepost(idx, removeNote: true),
                      );
                    }
                  }
                },
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.darkGrey,
                          backgroundImage:
                              (widget.post.repostUserAvatar != null &&
                                  widget.post.repostUserAvatar!.isNotEmpty)
                              ? NetworkImage(
                                  ApiConstants.getFullUrl(
                                    widget.post.repostUserAvatar!,
                                  ),
                                )
                              : null,
                          child:
                              (widget.post.repostUserAvatar == null ||
                                  widget.post.repostUserAvatar!.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                  size: 16,
                                )
                              : null,
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
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
                              size: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        (widget.post.repostNote != null &&
                                widget.post.repostNote!.trim().isNotEmpty)
                            ? widget.post.repostNote!
                            : 'Drop an emoji...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content
          GestureDetector(
            onDoubleTap: () {
              if (!widget.post.isLiked) widget.onLike();
              _showHeart.value = true;
              Future.delayed(
                const Duration(milliseconds: 700),
                () => _showHeart.value = false,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.post.mediaUrl.toLowerCase().endsWith('.mp4') ||
                    widget.post.mediaType == 'video')
                  _PostVideoPlayer(videoUrl: widget.post.mediaUrl)
                else
                  Image.network(
                    ApiConstants.getFullUrl(widget.post.mediaUrl),
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 350,
                        color: AppColors.surface,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: AppColors.surface,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white24,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                Obx(
                  () => AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: _showHeart.value ? 1.0 : 0.0,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 110,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onLike,
                  icon: Icon(
                    widget.post.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.post.isLiked ? Colors.red : Colors.white,
                    size: 27,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.bottomSheet(
                    CommentBottomSheet(id: widget.post.postId),
                    isScrollControlled: true,
                  ),
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap:
                      widget.onRepost ??
                      () {
                        if (Get.isRegistered<HomeController>()) {
                          final homeCtrl = Get.find<HomeController>();
                          final idx = homeCtrl.posts.indexWhere(
                            (p) => p.postId == widget.post.postId,
                          );
                          if (idx != -1) {
                            showRepostSheet(
                              context: context,
                              isCurrentlyReposted: widget.post.isReposted,
                              currentNote: widget.post.repostNote,
                              onRepost: (note) =>
                                  homeCtrl.toggleRepost(idx, note: note),
                              onRemoveRepost: () =>
                                  homeCtrl.toggleRepost(idx, removeNote: true),
                            );
                          }
                        }
                      },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          color: widget.post.isReposted
                              ? Colors.greenAccent
                              : Colors.white,
                          size: 24,
                        ),
                        if (widget.post.repostsCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${widget.post.repostsCount}',
                            style: TextStyle(
                              color: widget.post.isReposted
                                  ? Colors.greenAccent
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.bottomSheet(
                    ShareBottomSheet(
                      contentUrl: widget.post.mediaUrl,
                      postId: widget.post.postId,
                      postCaption: widget.post.caption,
                      postOwnerUsername: widget.post.username,
                    ),
                  ),
                  icon: const Icon(
                    Icons.send_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onSave,
                  icon: Icon(
                    widget.post.isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.likesCount > 0 || widget.post.repostsCount > 0)
                  Row(
                    children: [
                      if (widget.post.likesCount > 0)
                        Text(
                          '${widget.post.likesCount} likes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      if (widget.post.likesCount > 0 &&
                          widget.post.repostsCount > 0)
                        const Text(
                          ' • ',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13.5,
                          ),
                        ),
                      if (widget.post.repostsCount > 0)
                        Text(
                          '${widget.post.repostsCount} reposts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    children: [
                      TextSpan(
                        text: '${widget.post.username} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: widget.post.caption),
                    ],
                  ),
                ),
                if (widget.post.commentsCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: GestureDetector(
                      onTap: () => Get.bottomSheet(
                        CommentBottomSheet(id: widget.post.postId),
                        isScrollControlled: true,
                      ),
                      child: Text(
                        widget.post.commentsCount == 1
                            ? 'View 1 comment'
                            : 'View all ${widget.post.commentsCount} comments',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(widget.post.timestamp).toUpperCase(),
                  style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _PostVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _PostVideoPlayer({required this.videoUrl});

  @override
  State<_PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<_PostVideoPlayer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  final isInitialized = false.obs;
  final isMuted = false.obs;
  final showPlayIconBriefly = false.obs;
  final isPlaying = false.obs;
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
    _initVideo();
  }

  Future<void> _initVideo() async {
    isInitialized.value = false;
    final fullUrl = ApiConstants.getFullUrl(widget.videoUrl);
    _controller = VideoPlayerController.networkUrl(Uri.parse(fullUrl));
    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      isInitialized.value = true;
    } catch (e) {
      debugPrint("PostVideoPlayer init error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !isInitialized.value) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      isPlaying.value = false;
      showPlayIconBriefly.value = false;
    } else {
      _controller!.play();
      isPlaying.value = true;
      showPlayIconBriefly.value = true;
      _animController?.forward(from: 0.0).then((_) {
        showPlayIconBriefly.value = false;
      });
    }
  }

  void _toggleMute() {
    if (_controller == null) return;
    isMuted.value = !isMuted.value;
    _controller!.setVolume(isMuted.value ? 0.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!isInitialized.value || _controller == null) {
        return Container(
          height: 350,
          width: double.infinity,
          color: AppColors.surface,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      final playing = isPlaying.value || _controller!.value.isPlaying;

      return GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 350,
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
            if (!playing && !showPlayIconBriefly.value)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            if (showPlayIconBriefly.value)
              FadeTransition(
                opacity: _fadeAnimation!,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),

            if (!playing)
              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMuted.value ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
