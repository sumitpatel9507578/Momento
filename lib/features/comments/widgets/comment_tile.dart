import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/user_avatar.dart';
import '../../../widgets/verification_badge.dart';
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnlineAvatar(
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
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      children: [
                        TextSpan(
                          text: '${comment.username} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (comment.isVerified) ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: VerificationBadge(
                                isVerified: true,
                                size: 13,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
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
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatTime(comment.createdAt),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      if (comment.likeCount > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${comment.likeCount} likes',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (onReply != null) ...[
                        const SizedBox(width: 12),
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
                      ],
                    ],
                  ),
                  if (comment.replyCount > 0 && onViewReplies != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onViewReplies,
                      child: Text(
                        '—— View ${comment.replyCount} replies',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onLike,
              icon: Icon(
                comment.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                color: comment.isLikedByMe ? Colors.redAccent : Colors.white54,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }
}
