import 'package:flutter/material.dart';

import '../models/story_model.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class StoryItem extends StatelessWidget {
  final StoryModel? story;
  final UserStories? userStories;
  final bool isCurrentUser;
  final String? profileImage;
  final VoidCallback onTap;

  const StoryItem({
    super.key,
    this.story,
    this.userStories,
    this.isCurrentUser = false,
    this.profileImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final bool hasStories = isCurrentUser
        ? (userStories != null && userStories!.stories.isNotEmpty)
        : (userStories != null && userStories!.stories.isNotEmpty);

    final bool allViewed = isCurrentUser
        ? (userStories?.allViewed ?? true)
        : (userStories?.allViewed ?? story?.viewed ?? true);

    final String imgUrl = isCurrentUser
        ? (profileImage ?? userStories?.profileImage ?? '')
        : (userStories?.profileImage ?? story?.profileImage ?? '');

    final String displayName = isCurrentUser
        ? 'Your Story'
        : (userStories?.username ?? story?.username ?? 'User');

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          key: ValueKey(
            isCurrentUser
                ? 'current_user_story'
                : (userStories?.userId ?? story?.userId ?? 'story'),
          ),
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (isCurrentUser && !hasStories) || allViewed
                        ? null
                        : AppColors.primaryGradient,
                    border: (isCurrentUser && !hasStories) || allViewed
                        ? Border.all(color: Colors.white24, width: 2)
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: size.width * 0.08,
                    backgroundColor: AppColors.surface,
                    backgroundImage: imgUrl.isNotEmpty
                        ? NetworkImage(ApiConstants.getFullUrl(imgUrl))
                        : null,
                    child: imgUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white54,
                            size: 28,
                          )
                        : null,
                  ),
                ),
                if (isCurrentUser)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: TextStyle(
                color: isCurrentUser ? Colors.white70 : Colors.white,
                fontSize: 11,
                fontWeight: isCurrentUser ? FontWeight.normal : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
