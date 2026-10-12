import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/comment_service.dart';

class CommentController extends GetxController {
  final CommentService _commentService = Get.find<CommentService>();

  final comments = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final commentController = TextEditingController();

  Future<void> getComments(String id, {bool isReel = false}) async {
    try {
      isLoading.value = true;
      final result = await _commentService.fetchComments(id, isReel: isReel);
      comments.assignAll(result);
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
        await getComments(id, isReel: isReel); // Refresh
      } else {
        Get.snackbar('Error', 'Failed to post comment');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong');
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}
