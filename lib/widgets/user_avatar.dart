import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class UserAvatar extends StatefulWidget {
  final String? userId;
  final String? imageUrl;
  final double radius;
  final double? size;
  final bool showGradientBorder;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.userId,
    this.imageUrl,
    this.radius = 20,
    this.size,
    this.showGradientBorder = false,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _hasError = false;

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() {
        _hasError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.size != null ? widget.size! / 2 : widget.radius;
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty && !_hasError;
    final chatController = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : null;

    Widget avatar = CircleAvatar(
      radius: effectiveRadius,
      backgroundColor: widget.backgroundColor ?? AppColors.surface,
      backgroundImage: hasImage
          ? NetworkImage(ApiConstants.getFullUrl(widget.imageUrl!))
          : null,
      onBackgroundImageError: hasImage
          ? (exception, stackTrace) {
              if (mounted && !_hasError) {
                setState(() {
                  _hasError = true;
                });
              }
            }
          : null,
      child: !hasImage
          ? Icon(
              Icons.person,
              size: effectiveRadius * 0.9,
              color: Colors.white54,
            )
          : null,
    );

    if (widget.showGradientBorder) {
      avatar = Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
        ),
        child: avatar,
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (widget.userId != null && widget.userId!.isNotEmpty && chatController != null)
            Obx(() {
              final isOnline =
                  chatController.onlineUserIds.contains(widget.userId) &&
                  chatController.showActivityStatus.value;
              if (!isOnline) return const SizedBox.shrink();
              final dotSize = effectiveRadius * 0.45;
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
                      color: widget.borderColor ?? AppColors.background,
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
