import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../utils/app_colors.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onFollow;
  final VoidCallback onComment;
  final VoidCallback onMore;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
    required this.onFollow,
    required this.onComment,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: CircleAvatar(
                    radius: width * 0.045,
                    backgroundImage: NetworkImage(post.profileImage),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (post.location != null)
                      Text(
                        post.location!,
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: onFollow,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: post.isFollowing
                            ? Colors.white24
                            : AppColors.purple,
                      ),
                      color: post.isFollowing
                          ? Colors.transparent
                          : AppColors.purple.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      post.isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: post.isFollowing
                            ? Colors.white70
                            : AppColors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onMore,
                  icon: Icon(Icons.more_vert, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Post Media
          GestureDetector(
            onDoubleTap: onLike,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    post.mediaUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.purple,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surface,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white38,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Image unavailable',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Simple Like Animation could go here
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.02,
              vertical: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: post.isLiked ? Colors.redAccent : Colors.white,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: onComment,
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.send_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Spacer(),
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
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${post.likesCount} likes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '${post.username} ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: post.caption,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.commentsCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                      onTap: onComment,
                      child: Text(
                        'View all ${post.commentsCount} comments',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ),
                SizedBox(height: 4),
                Text(
                  _formatTimestamp(post.timestamp),
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
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
}
