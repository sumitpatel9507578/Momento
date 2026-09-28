import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController controller = Get.find<ChatController>();
  final TextEditingController messageController = TextEditingController();
  late final Map<String, dynamic> user;
  final RxBool _hasText = false.obs;

  @override
  void initState() {
    super.initState();
    user = Get.arguments as Map<String, dynamic>;
    controller.fetchMessages(user['id'].toString());
    messageController.addListener(() {
      _hasText.value = messageController.text.trim().isNotEmpty;
    });
  }

  bool get _isOnline => user['is_online'] == true || user['is_online'] == 1;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        user['profile_image'] != null &&
        user['profile_image'].toString().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        title: InkWell(
          onTap: () {},
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.darkGrey,
                backgroundImage: hasImage
                    ? NetworkImage(
                        ApiConstants.getFullUrl(user['profile_image']),
                      )
                    : null,
                child: !hasImage
                    ? const Icon(Icons.person, size: 18, color: Colors.white38)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user['full_name'] ?? user['username'] ?? 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isOnline ? 'Active now' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOnline ? Colors.white70 : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: const [
          Icon(Icons.call_outlined, color: Colors.white, size: 24),
          SizedBox(width: 18),
          Icon(Icons.videocam_outlined, color: Colors.white, size: 26),
          SizedBox(width: 18),
          Icon(Icons.info_outline, color: Colors.white, size: 24),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMessages.value &&
                  controller.messages.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.purple),
                );
              }

              final msgs = controller.messages;

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final realIndex = msgs.length - 1 - index;
                  final msg = msgs[realIndex];
                  final isMe = msg.senderId == controller.currentUserId;

                  // group consecutive messages from same sender
                  final prevMsg = realIndex > 0 ? msgs[realIndex - 1] : null;
                  final nextMsg = realIndex < msgs.length - 1
                      ? msgs[realIndex + 1]
                      : null;
                  final isFirstOfGroup =
                      prevMsg == null || prevMsg.senderId != msg.senderId;
                  final isLastOfGroup =
                      nextMsg == null || nextMsg.senderId != msg.senderId;
                  final isVeryLastMessage = realIndex == msgs.length - 1;

                  return _buildMessageRow(
                    text: msg.message,
                    isMe: isMe,
                    isFirstOfGroup: isFirstOfGroup,
                    isLastOfGroup: isLastOfGroup,
                    showSeen: isMe && isVeryLastMessage && msg.isRead,
                    showAvatar: !isMe && isLastOfGroup,
                    hasImage: hasImage,
                  );
                },
              );
            }),
          ),

          // Composer
          Container(
            padding: EdgeInsets.fromLTRB(
              8,
              8,
              12,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Message...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                          icon: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.white54,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                          icon: const Icon(
                            Icons.mic_none_rounded,
                            color: Colors.white54,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                          icon: const Icon(
                            Icons.image_outlined,
                            color: Colors.white54,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Obx(
                  () => _hasText.value
                      ? IconButton(
                          onPressed: () async {
                            final text = messageController.text.trim();
                            if (text.isNotEmpty) {
                              final success = await controller.sendMessage(
                                user['id'].toString(),
                                text,
                              );
                              if (success) messageController.clear();
                            }
                          },
                          icon: const Icon(
                            Icons.send_rounded,
                            color: AppColors.purple,
                            size: 24,
                          ),
                        )
                      : IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.favorite_border_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow({
    required String text,
    required bool isMe,
    required bool isFirstOfGroup,
    required bool isLastOfGroup,
    required bool showSeen,
    required bool showAvatar,
    required bool hasImage,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstOfGroup ? 8 : 2,
        bottom: showSeen ? 4 : 0,
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                SizedBox(
                  width: 28,
                  child: showAvatar
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.darkGrey,
                          backgroundImage: hasImage
                              ? NetworkImage(
                                  ApiConstants.getFullUrl(
                                    user['profile_image'],
                                  ),
                                )
                              : null,
                          child: !hasImage
                              ? const Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Colors.white38,
                                )
                              : null,
                        )
                      : null,
                ),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.purple : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(
                        isMe ? 20 : (isLastOfGroup ? 4 : 20),
                      ),
                      bottomRight: Radius.circular(
                        isMe ? (isLastOfGroup ? 4 : 20) : 20,
                      ),
                    ),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showSeen)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(
                'Seen',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
