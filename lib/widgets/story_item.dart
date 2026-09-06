import 'package:flutter/material.dart';

import '../models/story_model.dart';
import '../utils/app_colors.dart';

class StoryItem extends StatelessWidget {
  final StoryModel? story;
  final bool isCurrentUser;
  final VoidCallback onTap;

  const StoryItem({
    super.key,
    this.story,
    this.isCurrentUser = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (isCurrentUser || (story?.viewed ?? true))
                        ? null
                        : AppColors.primaryGradient,
                    border: (isCurrentUser || (story?.viewed ?? true))
                        ? Border.all(color: Colors.white24, width: 2)
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: size.width * 0.08,
                    backgroundColor: AppColors.surface,
                    backgroundImage: isCurrentUser
                        ? null
                        : NetworkImage(story!.profileImage),
                    child: isCurrentUser
                        ? Icon(Icons.person, color: Colors.white54, size: 30)
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
              isCurrentUser ? 'Your Story' : story!.username,
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
