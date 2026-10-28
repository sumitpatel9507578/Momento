import 'package:flutter/material.dart';
import 'package:momento/models/note_model.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/user_avatar.dart';

class NoteBubbleWidget extends StatelessWidget {
  final NoteModel? note;
  final bool isMine;
  final String? myProfileImage;
  final VoidCallback onTap;

  const NoteBubbleWidget({
    super.key,
    this.note,
    required this.isMine,
    this.myProfileImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarPath = isMine
        ? (myProfileImage ?? note?.profileImage ?? '')
        : (note?.profileImage ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // User Avatar
                  UserAvatar(
                    imageUrl: avatarPath,
                    size: 60,
                    showGradientBorder: note != null,
                  ),

                  // Note Text Cloud Bubble
                  if (note != null && note!.noteText.isNotEmpty)
                    Positioned(
                      top: -18,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 80),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24, width: 0.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          note!.noteText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else if (isMine)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isMine ? 'Your note' : (note?.username ?? 'Friend'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
