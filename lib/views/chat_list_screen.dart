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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_comment_outlined),
          ),
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
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 60,
                  color: Colors.white12,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchConversations,
          color: AppColors.purple,
          child: ListView.builder(
            itemCount: controller.conversations.length,
            itemBuilder: (context, index) {
              final convo = controller.conversations[index];
              return ListTile(
                onTap: () => Get.toNamed('/chat', arguments: convo),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      convo['profile_image'] != null &&
                          convo['profile_image'].isNotEmpty
                      ? NetworkImage(
                          ApiConstants.getFullUrl(convo['profile_image']),
                        )
                      : null,
                  child:
                      convo['profile_image'] == null ||
                          convo['profile_image'].isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  convo['full_name'] ?? convo['username'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  convo['lastMessage'] ?? 'Tap to chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                trailing: Text(
                  _formatTime(convo['lastMessageTime']),
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                ),
              );
            },
          ),
        );
      }),
    );
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
