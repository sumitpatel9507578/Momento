import 'package:flutter/material.dart';
import 'package:momento/features/comments/comments_sheet.dart';

class CommentBottomSheet extends StatelessWidget {
  final String id;
  final bool isReel;

  const CommentBottomSheet({super.key, required this.id, this.isReel = false});

  static Future<void> show(
    BuildContext context,
    String id, {
    bool isReel = false,
  }) async {
    await CommentsSheet.show(context, id, isReel: isReel);
  }

  @override
  Widget build(BuildContext context) {
    return CommentsSheet(id: id, isReel: isReel);
  }
}
