import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import 'comment_bottom_sheet.dart';
import 'share_bottom_sheet.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onFollow;
  final VoidCallback onComment;
  final VoidCallback? onMore;

  PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
    required this.onFollow,
    required this.onComment,
    this.onMore,
  });

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
                GestureDetector(
                  onTap: () => Get.toNamed('/profile', arguments: post.userId),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.surface,
                    backgroundImage: post.profileImage.isNotEmpty
                        ? NetworkImage(
                            ApiConstants.getFullUrl(post.profileImage),
                          )
                        : null,
                    child: post.profileImage.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white54,
                            size: 19,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        Get.toNamed('/profile', arguments: post.userId),
                    child: Text(
                      post.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      onMore ??
                      () {
                        PostCard.showPostOptionsBottomSheet(
                          context,
                          post,
                          onDelete: () {
                            if (Get.isRegistered<HomeController>()) {
                              Get.find<HomeController>().deletePost(
                                post.postId,
                              );
                            } else if (Get.isRegistered<ProfileController>(
                              tag: 'me',
                            )) {
                              Get.find<ProfileController>(
                                tag: 'me',
                              ).deletePost(post.postId);
                            }
                          },
                          onUpdateCaption: (newCaption) {
                            if (Get.isRegistered<HomeController>()) {
                              Get.find<HomeController>().updatePostCaption(
                                post.postId,
                                newCaption,
                              );
                            } else if (Get.isRegistered<ProfileController>(
                              tag: 'me',
                            )) {
                              Get.find<ProfileController>(
                                tag: 'me',
                              ).updatePostCaption(post.postId, newCaption);
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

          // Content
          GestureDetector(
            onDoubleTap: () {
              if (!post.isLiked) onLike();
              _showHeart.value = true;
              Future.delayed(
                const Duration(milliseconds: 700),
                () => _showHeart.value = false,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (post.mediaUrl.toLowerCase().endsWith('.mp4') ||
                    post.mediaType == 'video')
                  Container(
                    height: 350,
                    width: double.infinity,
                    color: AppColors.surface,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam, color: Colors.white24, size: 50),
                        SizedBox(height: 12),
                        Text(
                          'Video Post',
                          style: TextStyle(color: Colors.white24),
                        ),
                      ],
                    ),
                  )
                else
                  Image.network(
                    ApiConstants.getFullUrl(post.mediaUrl),
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
                  onPressed: onLike,
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.red : Colors.white,
                    size: 27,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.bottomSheet(
                    CommentBottomSheet(id: post.postId),
                    isScrollControlled: true,
                  ),
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.bottomSheet(
                    ShareBottomSheet(
                      contentUrl: post.mediaUrl,
                      postId: post.postId,
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
                  onPressed: onSave,
                  icon: Icon(
                    post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.likesCount > 0)
                  Text(
                    '${post.likesCount} likes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                const SizedBox(height: 5),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    children: [
                      TextSpan(
                        text: '${post.username} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
                if (post.commentsCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: GestureDetector(
                      onTap: () => Get.bottomSheet(
                        CommentBottomSheet(id: post.postId),
                        isScrollControlled: true,
                      ),
                      child: Text(
                        post.commentsCount == 1
                            ? 'View 1 comment'
                            : 'View all ${post.commentsCount} comments',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(post.timestamp).toUpperCase(),
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
