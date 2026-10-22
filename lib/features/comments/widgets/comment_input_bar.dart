import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/user_avatar.dart';

class CommentInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onPost;
  final VoidCallback onGallery;
  final String? replyingToUsername;
  final VoidCallback? onCancelReply;
  final String currentUsername;
  final String? currentProfileImage;

  const CommentInputBar({
    super.key,
    required this.controller,
    required this.onPost,
    required this.onGallery,
    this.replyingToUsername,
    this.onCancelReply,
    required this.currentUsername,
    this.currentProfileImage,
  });

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mira AI Suggestions
          Obx(() {
            if (_isGenerating.value) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  height: 30,
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.purple, size: 14),
                      SizedBox(width: 8),
                      Text('Mira is thinking...', style: TextStyle(color: Colors.purple, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }
            
            if (_miraSuggestions.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _miraSuggestions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final suggestion = _miraSuggestions[index];
                    return ActionChip(
                      label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.auto_awesome, color: Colors.purple, size: 14),
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: Colors.purple.withValues(alpha: 0.3),
                      ),
                      onPressed: () {
                        widget.controller.text = suggestion;
                      },
                    );
                  },
                ),
              ),
            );
          }),

          if (widget.replyingToUsername != null) ...[
            Row(
              children: [
                Text(
                  'Replying to @${widget.replyingToUsername}',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onCancelReply,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserAvatar(imageUrl: widget.currentProfileImage, radius: 16),
              const SizedBox(width: 10),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onGallery,
                icon: const Icon(
                  Icons.image_outlined,
                  color: Colors.white70,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: widget.replyingToUsername != null
                        ? 'Reply to @${widget.replyingToUsername}...'
                        : 'Add a comment...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 13.5,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: hasText ? widget.onPost : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasText ? Colors.blueAccent : Colors.grey[800],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: hasText ? Colors.white : Colors.white38,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
