import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class ShareBottomSheet extends StatelessWidget {
  const ShareBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // final width = size.width;

    final platforms = [
      {
        'name': 'WhatsApp',
        'icon': Icons.chat_bubble_rounded,
        'color': Colors.green,
      },
      {
        'name': 'Messenger',
        'icon': Icons.message_rounded,
        'color': Colors.blue,
      },
      {'name': 'Twitter', 'icon': Icons.tag_rounded, 'color': Colors.lightBlue},
      {'name': 'Copy Link', 'icon': Icons.link_rounded, 'color': Colors.grey},
      {
        'name': 'More',
        'icon': Icons.more_horiz_rounded,
        'color': AppColors.purple,
      },
    ];

    return GlassContainer(
      height: size.height * 0.45,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Share to',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 30),

          // Platforms Row
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: platforms.length,
              itemBuilder: (context, index) {
                final p = platforms[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: (p['color'] as Color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          p['icon'] as IconData,
                          color: p['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        p['name'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 20),

          // Send to friends search placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Send to friends...',
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
