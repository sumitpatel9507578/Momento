import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/comment_service.dart';

class CommentController extends GetxController {
  final CommentService _commentService = Get.find<CommentService>();

  final comments = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final commentController = TextEditingController();

  final likedCommentIds = <String>{}.obs;
  final commentLikeCounts = <String, int>{}.obs;

  Future<void> getComments(String id, {bool isReel = false}) async {
    try {
      isLoading.value = true;
      final result = await _commentService.fetchComments(id, isReel: isReel);
      comments.assignAll(result);
      for (final c in result) {
        final cId = (c['id'] ?? c['_id'] ?? c['commentId'])?.toString();
        if (cId != null) {
          final liked =
              c['isLiked'] == true ||
              c['is_liked'] == true ||
              c['liked'] == true ||
              c['isLiked'] == 1 ||
              c['liked'] == 1;
          if (liked) {
            likedCommentIds.add(cId);
          } else {
            likedCommentIds.remove(cId);
          }
          final cnt =
              int.tryParse(
                (c['likesCount'] ??
                        c['likes_count'] ??
                        c['likes'] ??
                        c['like_count'] ??
                        0)
                    .toString(),
              ) ??
              0;
          commentLikeCounts[cId] = cnt;
        }
      }
      likedCommentIds.refresh();
      commentLikeCounts.refresh();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> postComment(String id, {bool isReel = false}) async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final success = await _commentService.addComment(
        id,
        text,
        isReel: isReel,
      );
      if (success) {
        commentController.clear();
        await getComments(id, isReel: isReel);
      } else {
        Get.snackbar('Error', 'Failed to post comment');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong');
    }
  }

  Future<void> toggleLike(
    String commentId,
    String targetId, {
    bool isReel = false,
  }) async {
    final currentlyLiked = likedCommentIds.contains(commentId);
    final currentCount = commentLikeCounts[commentId] ?? 0;

    // Instant Optimistic UI Update
    if (currentlyLiked) {
      likedCommentIds.remove(commentId);
      commentLikeCounts[commentId] = (currentCount - 1).clamp(0, 999999);
    } else {
      likedCommentIds.add(commentId);
      commentLikeCounts[commentId] = currentCount + 1;
    }
    likedCommentIds.refresh();
    commentLikeCounts.refresh();

    final success = await _commentService.likeComment(
      commentId,
      targetId: targetId,
      isReel: isReel,
    );

    if (!success) {
      // Revert if failed
      if (currentlyLiked) {
        likedCommentIds.add(commentId);
        commentLikeCounts[commentId] = currentCount;
      } else {
        likedCommentIds.remove(commentId);
        commentLikeCounts[commentId] = currentCount;
      }
      likedCommentIds.refresh();
      commentLikeCounts.refresh();
      Get.snackbar('Error', 'Failed to update like');
    }
  }

  Future<void> editComment(
    String commentId,
    String newText,
    String targetId, {
    bool isReel = false,
  }) async {
    if (newText.trim().isEmpty) return;
    final success = await _commentService.editComment(
      commentId,
      newText.trim(),
      targetId: targetId,
      isReel: isReel,
    );
    if (success) {
      await getComments(targetId, isReel: isReel);
      Get.snackbar('Success', 'Comment updated');
    } else {
      Get.snackbar('Error', 'Failed to update comment');
    }
  }

  Future<void> deleteComment(
    String commentId,
    String targetId, {
    bool isReel = false,
  }) async {
    final success = await _commentService.deleteComment(
      commentId,
      targetId: targetId,
      isReel: isReel,
    );
    if (success) {
      comments.removeWhere(
        (c) => (c['id'] ?? c['_id'] ?? c['commentId'])?.toString() == commentId,
      );
      likedCommentIds.remove(commentId);
      commentLikeCounts.remove(commentId);
      Get.snackbar('Success', 'Comment deleted');
    } else {
      Get.snackbar('Error', 'Failed to delete comment');
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}
