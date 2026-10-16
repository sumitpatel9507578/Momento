import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? userId;
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.userId,
    this.imageUrl,
    this.radius = 20,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final chatController = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor ?? AppColors.surface,
            backgroundImage: hasImage
                ? NetworkImage(ApiConstants.getFullUrl(imageUrl!))
                : null,
            child: !hasImage
                ? Icon(
                    Icons.person,
                    size: radius * 0.9,
                    color: Colors.white54,
                  )
                : null,
          ),
          if (userId != null && userId!.isNotEmpty && chatController != null)
            Obx(() {
              final isOnline = chatController.onlineUserIds.contains(userId) &&
                  chatController.showActivityStatus.value;
              if (!isOnline) return const SizedBox.shrink();
              final dotSize = radius * 0.45;
              return Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: dotSize.clamp(10.0, 14.0),
                  height: dotSize.clamp(10.0, 14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ED573),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor ?? AppColors.background,
                      width: 2,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

typedef OnlineAvatar = UserAvatar;
