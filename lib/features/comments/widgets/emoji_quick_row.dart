import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class EmojiQuickRow extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;

  const EmojiQuickRow({super.key, required this.onEmojiSelected});

  static const emojis = ['❤️', '🙌', '🔥', '👏', '😢', '😍', '😮', '😂'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: emojis.map((emoji) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => onEmojiSelected(emoji),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
