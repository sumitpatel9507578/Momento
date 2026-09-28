import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/comment_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

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
    // final size = MediaQuery.sizeOf(context);
    final height = MediaQuery.of(context).size.height;

    return GlassContainer(
      height: height * 0.7,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
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
                padding: const EdgeInsets.all(20),
                itemCount: controller.comments.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage:
                            comment['profileImage'] != null &&
                                comment['profileImage'].isNotEmpty
                            ? NetworkImage(
                                ApiConstants.getFullUrl(
                                  comment['profileImage'],
                                ),
                              )
                            : null,
                        child:
                            comment['profileImage'] == null ||
                                comment['profileImage'].isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white24,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
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
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(comment['createdAt']),
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      controller.postComment(widget.id, isReel: widget.isReel),
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.bold,
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
