import 'package:flutter/material.dart';

import '../models/story_model.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class StoryItem extends StatelessWidget {
  final StoryModel? story;
  final bool isCurrentUser;
  final String? profileImage;
  final VoidCallback onTap;

  const StoryItem({
    super.key,
    this.story,
    this.isCurrentUser = false,
    this.profileImage,
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
                        ? (profileImage != null && profileImage!.isNotEmpty
                              ? NetworkImage(
                                  ApiConstants.getFullUrl(profileImage!),
                                )
                              : null)
                        : (story != null && story!.profileImage.isNotEmpty
                              ? NetworkImage(
                                  ApiConstants.getFullUrl(story!.profileImage),
                                )
                              : null),
                    child:
                        ((isCurrentUser &&
                                (profileImage == null ||
                                    profileImage!.isEmpty)) ||
                            (!isCurrentUser &&
                                (story == null || story!.profileImage.isEmpty)))
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
