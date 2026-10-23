import 'package:flutter/material.dart';

class MiraAiButton extends StatelessWidget {
  final String label;
  final bool compact;
  final VoidCallback? onPressed;
  final IconData icon;

  const MiraAiButton({
    super.key,
    this.label = 'Write with Mira',
    this.compact = false,
    this.onPressed,
    this.icon = Icons.auto_awesome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8E2DE2),
            Color(0xFF4A00E0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 16,
              vertical: compact ? 6 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: compact ? 14 : 18,
                ),
                SizedBox(width: compact ? 4 : 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
