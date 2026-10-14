import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class ChatListScreen extends GetView<ChatController> {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Row(
          children: [
            const SizedBox(width: 4),
            Obx(
              () => Text(
                controller.currentUsername.value.isEmpty
                    ? 'Messages'
                    : '@${controller.currentUsername.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.videocam_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_square, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.conversations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        if (controller.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Start a conversation with someone.',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchConversations,
          color: AppColors.purple,
          backgroundColor: AppColors.surface,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4),
            itemCount: controller.conversations.length,
            itemBuilder: (context, index) {
              final convo = controller.conversations[index];
              final profileImage =
                  convo['profile_image'] ?? convo['profileImage'];
              final hasImage =
                  profileImage != null && profileImage.toString().isNotEmpty;
              final isUnread =
                  convo['unread'] == true ||
                  convo['unread'] == 1 ||
                  (convo['isRead'] != true &&
                      convo['receiverId']?.toString() ==
                          controller.currentUserId);
              final conversationUserId =
                  (convo['conversationUserId'] ??
                          convo['conversation_user_id'] ??
                          convo['userId'] ??
                          convo['id'] ??
                          '')
                      .toString();
              final isOnline = controller.onlineUserIds.contains(
                conversationUserId,
              );

              return InkWell(
                onTap: () => Get.toNamed('/chat', arguments: convo),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 29,
                            backgroundColor: AppColors.darkGrey,
                            backgroundImage: hasImage
                                ? NetworkImage(
                                    ApiConstants.getFullUrl(profileImage),
                                  )
                                : null,
                            child: !hasImage
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white38,
                                  )
                                : null,
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF2ED573),
                                  border: Border.all(
                                    color: AppColors.background,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              convo['full_name'] ??
                                  convo['name'] ??
                                  convo['username'] ??
                                  'User',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _subtitleText(convo),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isUnread ? Colors.white : Colors.white38,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.purple,
                          ),
                        ),
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white54,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  String _subtitleText(Map<String, dynamic> convo) {
    final msg = convo['lastMessage'] ?? convo['message'] ?? 'Tap to chat';
    final time = _formatTime(convo['lastMessageTime'] ?? convo['createdAt']);
    if (time.isEmpty) return msg;
    return '$msg · $time';
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    try {
      final date = DateTime.parse(time);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'Now';
    } catch (_) {
      return '';
    }
  }
}
