import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/chat_controller.dart';
import '../controllers/reel_controller.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
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
    final args = Get.arguments;
    if (args is UserModel) {
      user = {
        'id': args.uid,
        'full_name': args.name,
        'username': args.username,
        'profile_image': args.profileImage,
        'is_online': false,
      };
    } else if (args is Map) {
      user = Map<String, dynamic>.from(args);
    } else {
      final str = args?.toString() ?? '';
      user = {
        'id': str,
        'full_name': 'User',
        'username': str,
        'profile_image': '',
      };
    }
    final targetUserId = _targetUserId;
    controller.messages.clear();
    controller.startLiveMessages(targetUserId);
    messageController.addListener(() {
      _hasText.value = messageController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    controller.stopLiveMessages();
    messageController.dispose();
    super.dispose();
  }

  String get _targetUserId =>
      (user['conversationUserId'] ??
              user['conversation_user_id'] ??
              user['userId'] ??
              user['user_id'] ??
              user['uid'] ??
              user['_id'] ??
              user['id'] ??
              '')
          .toString();

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;
      controller.onMessageInput(_targetUserId, false);
      await controller.sendImage(_targetUserId, image.path);
    } catch (error) {
      Get.snackbar('Photo not sent', 'Could not select this photo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = user['profile_image'] ?? user['profileImage'];
    final hasImage = profileImage != null && profileImage.toString().isNotEmpty;

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
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.darkGrey,
                    backgroundImage: hasImage
                        ? NetworkImage(ApiConstants.getFullUrl(profileImage))
                        : null,
                    child: !hasImage
                        ? const Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.white38,
                          )
                        : null,
                  ),
                  Obx(
                    () => controller.peerOnline.value
                        ? Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.background,
                                  width: 2,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user['full_name'] ??
                          user['name'] ??
                          user['username'] ??
                          'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Obx(() {
                      final isOnline = controller.peerOnline.value;
                      final subtitle = controller.peerTyping.value
                          ? 'Typing...'
                          : controller.socketError.value.isNotEmpty
                          ? 'Chat unavailable'
                          : !controller.socketConnected.value
                          ? 'Connecting...'
                          : isOnline
                          ? 'Active now'
                          : 'Offline';
                      return Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.peerTyping.value
                              ? AppColors.purple
                              : isOnline
                              ? Colors.white70
                              : Colors.white38,
                        ),
                      );
                    }),
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
              if (msgs.isEmpty && controller.messageLoadError.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          color: Colors.white54,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.messageLoadError.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => controller.fetchMessages(
                            controller.activeChatUserId ?? '',
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

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
                    msg: msg,
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
              12,
              10,
              12,
              MediaQuery.of(context).padding.bottom + 10,
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
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      maxHeight: 120,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            onChanged: (text) => controller.onMessageInput(
                              _targetUserId,
                              text.trim().isNotEmpty,
                            ),
                            minLines: 1,
                            maxLines: 5,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Message...',
                              hintStyle: TextStyle(
                                color: Colors.white38,
                                fontSize: 15,
                              ),
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
                          onPressed: () =>
                              _pickAndSendImage(ImageSource.camera),
                          icon: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white54,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              _pickAndSendImage(ImageSource.gallery),
                          icon: const Icon(
                            Icons.image_outlined,
                            color: Colors.white54,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => _hasText.value
                      ? Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.purple,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () async {
                              final text = messageController.text.trim();
                              if (text.isNotEmpty) {
                                messageController.clear();
                                final targetId = _targetUserId;
                                controller.onMessageInput(targetId, false);
                                await controller.sendMessage(targetId, text);
                              }
                            },
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () async {
                              final targetId = _targetUserId;
                              controller.onMessageInput(targetId, false);
                              await controller.sendMessage(targetId, '❤️');
                            },
                            icon: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.redAccent,
                              size: 22,
                            ),
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

  void _showMessageMenu(BuildContext context, MessageModel msg) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Wrap(
          children: [
            Obx(() {
              final isSaving = controller.savingMessageIds.contains(msg.id);
              return ListTile(
                enabled: msg.isPersisted && !isSaving,
                leading: isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        msg.isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border_rounded,
                        color: Colors.white,
                      ),
                title: Text(
                  msg.isSaved ? 'Unsave Message' : 'Save Message',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Get.back();
                  controller.toggleSaveMessage(msg);
                },
              );
            }),
            if (msg.messageType == 'reel' &&
                msg.reelId != null &&
                msg.reelId!.isNotEmpty)
              Obx(() {
                final isSaving = controller.savingReelIds.contains(msg.reelId);
                final isSaved = controller.isReelSaved(msg.reelId!);
                return ListTile(
                  enabled: !isSaving,
                  leading: isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isSaved
                              ? Icons.video_library
                              : Icons.video_library_outlined,
                          color: Colors.white,
                        ),
                  title: Text(
                    isSaved ? 'Unsave Shared Reel' : 'Save Shared Reel',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Get.back();
                    controller.toggleSaveReel(msg.reelId!, isSaved: isSaved);
                  },
                );
              }),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.white54),
              title: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow({
    required MessageModel msg,
    required bool isMe,
    required bool isFirstOfGroup,
    required bool isLastOfGroup,
    required bool showSeen,
    required bool showAvatar,
    required bool hasImage,
  }) {
    final text = msg.message;
    final isSharedReel = msg.messageType == 'reel' && msg.reelId != null;
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
              GestureDetector(
                onLongPress: () => _showMessageMenu(context, msg),
                child: ConstrainedBox(
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: isSharedReel
                              ? InkWell(
                                  onTap: () => _openSharedReel(msg.reelId!),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg.reelCaption?.isNotEmpty ==
                                                      true
                                                  ? msg.reelCaption!
                                                  : 'Shared reel',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.5,
                                                height: 1.25,
                                              ),
                                            ),
                                            if (msg
                                                    .reelOwnerUsername
                                                    ?.isNotEmpty ==
                                                true)
                                              Text(
                                                '@${msg.reelOwnerUsername}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (msg.messageType == 'video')
                                      const SizedBox(
                                        width: 220,
                                        height: 150,
                                        child: Center(
                                          child: Icon(
                                            Icons.play_circle_fill,
                                            size: 48,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    else
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          ApiConstants.getFullUrl(msg.mediaUrl),
                                          width: 220,
                                          height: 220,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                _,
                                                error,
                                                stackTrace,
                                              ) => const SizedBox(
                                                width: 220,
                                                height: 120,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                    color: Colors.white54,
                                                    size: 30,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                    if (text.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : Text(
                                  text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    height: 1.25,
                                  ),
                                ),
                        ),
                        if (msg.isSaved) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.bookmark,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showSeen)
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 4),
              child: Text(
                'Seen',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          if (isMe && msg.isPending)
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 4),
              child: Text(
                'Waiting for connection',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openSharedReel(String reelId) async {
    final reelController = Get.isRegistered<ReelController>()
        ? Get.find<ReelController>()
        : Get.put(ReelController());
    if (await reelController.openReel(reelId)) {
      Get.toNamed(AppRoutes.reels, arguments: reelId);
    }
  }
}
