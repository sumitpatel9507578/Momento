import 'package:flutter/material.dart';
import 'package:momento/features/comments/comments_sheet.dart';

class CommentBottomSheet extends StatelessWidget {
  final String id;
  final bool isReel;

  const CommentBottomSheet({super.key, required this.id, this.isReel = false});

  @override
  Widget build(BuildContext context) {
    return CommentsSheet(id: id, isReel: isReel);
  }
}
