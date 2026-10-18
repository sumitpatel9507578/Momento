import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/features/comments/models/comment_model.dart';
import 'package:momento/features/comments/widgets/comment_input_bar.dart';
import 'package:momento/features/comments/widgets/comment_tile.d'
    'art';
import 'package:momento/features/comments/widgets/emoji_quick_row.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/services/chat_socket_service.dart';
import 'package:momento/services/comment_service.dart';
import 'package:momento/utils/app_colors.dart';

class CommentsSheet extends StatefulWidget {
  final String id;
  final bool isReel;
  const CommentsSheet({super.key, required this.id, this.isReel = false});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late final CommentService _commentService;
  late final ApiService _apiService;
  late final ChatSocketService _socketService;

  final comments = <CommentModel>[].obs;
  final isLoading = true.obs;
  final hasError = false.obs;
  final sortOption = 'newest'.obs; // 'top' or 'newest'
  final commentController = TextEditingController();

  String? replyingToCommentId;
  String? replyingToUsername;
  String? currentUsername;
  String? currentProfileImage;
  String? currentUserId;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _apiService = Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put(ApiService(), permanent: true);
    _commentService = Get.isRegistered<CommentService>()
        ? Get.find<CommentService>()
        : Get.put(CommentService(_apiService));
    _socketService = Get.isRegistered<ChatSocketService>()
        ? Get.find<ChatSocketService>()
        : Get.put(ChatSocketService(apiService: _apiService));

    _loadUserAndComments();

    // Socket real-time sync across users
    _socketService.joinPostRoom(widget.id);
    _socketService.onCommentAdded = (data) {
      if (data['postId']?.toString() == widget.id ||
          data['id']?.toString() == widget.id ||
          data['reelId']?.toString() == widget.id) {
        _fetchComments(silent: true);
      }
    };
    _socketService.onCommentLiked = (data) {
      _fetchComments(silent: true);
    };
    _socketService.onCommentDeleted = (data) {
      _fetchComments(silent: true);
    };

    // Fallback polling timer every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _fetchComments(silent: true);
      }
    });
  }

  Future<void> _loadUserAndComments() async {
    try {
      final user = await _apiService.getUser();
      currentUserId = (user?['id'] ?? user?['uid'] ?? user?['userId'])
          ?.toString();
      if (mounted) {
        setState(() {
          currentUsername = user?['username'] ?? user?['name'];
          currentProfileImage = user?['profileImage'] ?? user?['profile_image'];
        });
      }
    } catch (_) {}
    await _fetchComments();
  }

  Future<void> _fetchComments({bool silent = false}) async {
    try {
      if (!silent) isLoading.value = true;
      hasError.value = false;
      final result = await _commentService.fetchComments(
        widget.id,
        isReel: widget.isReel,
      );
      final parsedComments = result
          .map((json) => CommentModel.fromJson(json))
          .toList();

      final pendingComments = comments.where((c) => c.isPending).toList();
      comments.assignAll([...pendingComments, ...parsedComments]);
    } catch (_) {
      if (!silent) hasError.value = true;
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> _postComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    final tempComment = CommentModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      postId: widget.id,
      parentId: replyingToCommentId,
      userId: currentUserId ?? 'me',
      username: currentUsername ?? 'You',
      profileImage: currentProfileImage ?? '',
      text: text,
      createdAt: DateTime.now(),
      isPending: true,
      isAuthor: true,
    );

    comments.insert(0, tempComment);
    commentController.clear();
    final parentIdCopy = replyingToCommentId;
    if (mounted) {
      setState(() {
        replyingToCommentId = null;
        replyingToUsername = null;
      });
    }

    try {
      final success = await _commentService.addComment(
        widget.id,
        text,
        isReel: widget.isReel,
        parentId: parentIdCopy,
      );
      comments.removeWhere((c) => c.id == tempComment.id);
      if (success) {
        await _fetchComments();
      } else {
        Get.snackbar('Error', 'Couldn\'t post comment');
      }
    } catch (_) {
      comments.removeWhere((c) => c.id == tempComment.id);
      Get.snackbar('Error', 'Couldn\'t post comment');
    }
  }

  Future<void> _toggleLike(CommentModel comment) async {
    final index = comments.indexWhere((c) => c.id == comment.id);
    if (index == -1) return;

    final updated = comment.copyWith(
      isLikedByMe: !comment.isLikedByMe,
      likeCount: comment.isLikedByMe
          ? comment.likeCount - 1
          : comment.likeCount + 1,
    );
    comments[index] = updated;

    final success = await _commentService.likeComment(
      comment.id,
      targetId: widget.id,
      isReel: widget.isReel,
    );
    if (!success) {
      comments[index] = comment;
    }
  }

  void _showCommentOptions(String commentId, String currentText) {
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
                _showEditDialog(commentId, currentText);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Delete Comment',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                Get.back();
                final success = await _commentService.deleteComment(
                  commentId,
                  targetId: widget.id,
                  isReel: widget.isReel,
                );
                if (success) {
                  comments.removeWhere((c) => c.id == commentId);
                  Get.snackbar('Success', 'Comment deleted');
                } else {
                  Get.snackbar('Error', 'Failed to delete comment');
                }
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

  void _showEditDialog(String commentId, String currentText) {
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
            onPressed: () async {
              final newText = editController.text.trim();
              Get.back();
              if (newText.isNotEmpty) {
                final success = await _commentService.editComment(
                  commentId,
                  newText,
                  targetId: widget.id,
                  isReel: widget.isReel,
                );
                if (success) {
                  await _fetchComments();
                  Get.snackbar('Success', 'Comment updated');
                } else {
                  Get.snackbar('Error', 'Failed to update comment');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socketService.leavePostRoom(widget.id);
    _socketService.onCommentAdded = null;
    _socketService.onCommentLiked = null;
    _socketService.onCommentDeleted = null;
    _pollingTimer?.cancel();
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Comments',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

            // Comments List (Flexible height bounded)
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Obx(() {
                  if (isLoading.value && comments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: AppColors.purple,
                        ),
                      ),
                    );
                  }

                  if (hasError.value && comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Couldn\'t load comments',
                            style: TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _fetchComments,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (comments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No comments yet. Start the conversation.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: comments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return CommentTile(
                        comment: comment,
                        onLike: () => _toggleLike(comment),
                        onLongPress: () {
                          // ONLY open options dialog if long-pressed on own comment or author
                          if (comment.userId == currentUserId ||
                              comment.isAuthor) {
                            _showCommentOptions(comment.id, comment.text);
                          }
                        },
                        onReply: () {
                          if (mounted) {
                            setState(() {
                              replyingToCommentId = comment.id;
                              replyingToUsername = comment.username;
                            });
                          }
                          commentController.text = '@${comment.username} ';
                        },
                      );
                    },
                  );
                }),
              ),
            ),

            // Emoji Quick Row
            EmojiQuickRow(
              onEmojiSelected: (emoji) {
                commentController.text += emoji;
                commentController.selection = TextSelection.fromPosition(
                  TextPosition(offset: commentController.text.length),
                );
              },
            ),

            // Input Bar
            CommentInputBar(
              controller: commentController,
              onPost: _postComment,
              onGallery: () =>
                  Get.snackbar('Gallery', 'Photo comment feature coming soon'),
              replyingToUsername: replyingToUsername,
              onCancelReply: () {
                if (mounted) {
                  setState(() {
                    replyingToCommentId = null;
                    replyingToUsername = null;
                  });
                }
              },
              currentUsername: currentUsername ?? 'You',
              currentProfileImage: currentProfileImage,
            ),
          ],
        ),
      ),
    );
  }
}
