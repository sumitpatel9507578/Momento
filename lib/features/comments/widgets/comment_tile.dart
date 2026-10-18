import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/user_avatar.dart';
import '../models/comment_model.dart';

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onLike;
  final VoidCallback onLongPress;
  final VoidCallback? onReply;
  final VoidCallback? onViewReplies;

  const CommentTile({
    super.key,
    required this.comment,
    required this.onLike,
    required this.onLongPress,
    this.onReply,
    this.onViewReplies,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onDoubleTap: onLike,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              userId: comment.userId,
              imageUrl: comment.profileImage,
              radius: 18,
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
                          text: '${comment.username}  ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (comment.isAuthor) ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Author',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                        TextSpan(
                          text: comment.text,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        comment.timeAgo,
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (onReply != null)
                        GestureDetector(
                          onTap: onReply,
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (comment.isLikedByAuthor) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.favorite, color: Colors.redAccent, size: 10),
                        const SizedBox(width: 4),
                        const Text(
                          'Liked by author',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    comment.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                    color: comment.isLikedByMe ? Colors.redAccent : Colors.white54,
                    size: 16,
                  ),
                  onPressed: onLike,
                ),
                if (comment.likeCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${comment.likeCount}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
