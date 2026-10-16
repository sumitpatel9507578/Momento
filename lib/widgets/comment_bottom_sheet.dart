import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/widgets/user_avatar.dart';

import '../controllers/comment_controller.dart';
import '../utils/app_colors.dart';

class CommentBottomSheet extends StatefulWidget {
  final String id;
  final bool isReel;
  const CommentBottomSheet({super.key, required this.id, this.isReel = false});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final CommentController controller = Get.find<CommentController>();

  @override
  void initState() {
    super.initState();
    controller.getComments(widget.id, isReel: widget.isReel);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: height * 0.4,
          minHeight: height * 0.2,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 32,
              height: 3.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Comments',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.comments.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.purple),
                );
              }

              if (controller.comments.isEmpty) {
                return const Center(
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    itemCount: controller.comments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final comment = controller.comments[index];
                      final commentId =
                          (comment['id'] ??
                                  comment['_id'] ??
                                  comment['commentId'])
                              .toString();
                      final userId =
                          (comment['userId'] ??
                                  comment['user_id'] ??
                                  comment['author'] ??
                                  '')
                              .toString();

                      return GestureDetector(
                        onLongPress: () => _showCommentOptions(
                          context,
                          commentId,
                          comment['comment']?.toString() ?? '',
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserAvatar(
                              userId: userId,
                              imageUrl: comment['profileImage'],
                              radius: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${comment['username']}  ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: comment['comment'] as String,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(comment['createdAt']),
                                    style: const TextStyle(
                                      color: Colors.white24,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Obx(() {
                              final isLiked = controller.likedCommentIds
                                  .contains(commentId);
                              final likesCount =
                                  controller.commentLikeCounts[commentId] ?? 0;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked
                                      ? Colors.redAccent
                                      : Colors.white54,
                                  size: 16,
                                ),
                                onPressed: () => controller.toggleLike(
                                  commentId,
                                  widget.id,
                                  isReel: widget.isReel,
                                ),
                              ),
                              if (likesCount > 0)
                                Text(
                                  '$likesCount',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            }),
          ),

          // Quick Reaction Emojis Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['❤️', '🙌', '🔥', '👏', '😢', '😍', '😮', '😂'].map((
                  emoji,
                ) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: GestureDetector(
                      onTap: () {
                        controller.commentController.text += emoji;
                        controller
                            .commentController
                            .selection = TextSelection.fromPosition(
                          TextPosition(
                            offset: controller.commentController.text.length,
                          ),
                        );
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Instagram-style Input Bar with Gallery & Upward Arrow Send Button
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: const BoxDecoration(color: AppColors.surface),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    Get.snackbar('Gallery', 'Photo comment feature');
                  },
                  icon: const Icon(
                    Icons.image_outlined,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: controller.commentController,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.38),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      controller.postComment(widget.id, isReel: widget.isReel),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentOptions(
    BuildContext context,
    String commentId,
    String currentText,
  ) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                'Edit Comment',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                _showEditDialog(context, commentId, currentText);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Delete Comment',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Get.back();
                controller.deleteComment(
                  commentId,
                  widget.id,
                  isReel: widget.isReel,
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

  void _showEditDialog(
    BuildContext context,
    String commentId,
    String currentText,
  ) {
    final editController = TextEditingController(text: currentText);
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Edit Comment',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Edit your comment...',
            hintStyle: TextStyle(color: Colors.white38),
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
              controller.editComment(
                commentId,
                editController.text,
                widget.id,
                isReel: widget.isReel,
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return "Just now";
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'Just now';
    } catch (_) {
      return "Just now";
    }
  }
}
