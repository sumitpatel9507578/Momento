import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:momento/controllers/chat_controller.dart';
import 'package:momento/controllers/reel_controller.dart';
import 'package:momento/models/message_model.dart';
import 'package:momento/models/post_model.dart';
import 'package:momento/models/user_model.dart';
import 'package:momento/routes/app_routes.dart';
import 'package:momento/utils/api_constants.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/user_avatar.dart';

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
              OnlineAvatar(
                userId: _targetUserId,
                imageUrl: profileImage,
                radius: 18,
                backgroundColor: AppColors.darkGrey,
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
                      final isOnline =
                          controller.isUserOnline(_targetUserId) &&
                          controller.showActivityStatus.value;
                      final subtitle = controller.peerTyping.value
                          ? 'Typing...'
                          : controller.socketError.value.isNotEmpty
                          ? 'Chat unavailable'
                          : !controller.socketConnected.value
                          ? 'Connecting...'
                          : isOnline
                          ? 'Online'
                          : _formatLastSeen(
                              user['lastSeen'] ?? user['last_seen'],
                            );
                      return Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.peerTyping.value
                              ? AppColors.purple
                              : isOnline
                              ? const Color(0xFF2ED573)
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

          // Single Unified Composer
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            color: AppColors.background,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white12, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: () => _pickAndSendImage(ImageSource.camera),
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: () => _pickAndSendImage(ImageSource.gallery),
                    icon: const Icon(
                      Icons.image_outlined,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
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
                  Obx(
                    () => _hasText.value
                        ? IconButton(
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
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
                              color: AppColors.purple,
                              size: 22,
                            ),
                          )
                        : IconButton(
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
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
                ],
              ),
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
            if ((msg.messageType == 'post' || msg.isPostShare) &&
                (msg.postId != null && msg.postId!.isNotEmpty))
              Obx(() {
                final postId = msg.postId!;
                final isSaving = controller.savingPostIds.contains(postId);
                final isSaved = controller.savedPosts.any(
                  (p) => p.postId == postId,
                );
                return ListTile(
                  enabled: !isSaving,
                  leading: isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.white,
                        ),
                  title: Text(
                    isSaved ? 'Unsave Shared Post' : 'Save Shared Post',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Get.back();
                    controller.toggleSavePost(postId, isSaved: isSaved);
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

    String? extractedPostId = msg.postId;
    String? extractedPostImageUrl = msg.postImageUrl;
    String? extractedPostCaption = msg.postCaption;
    String? extractedPostOwnerUsername = msg.postOwnerUsername;

    if (!msg.isPostShare && msg.message.contains('/posts/')) {
      try {
        final parts = msg.message.split('/posts/');
        if (parts.length > 1) {
          extractedPostId = parts[1].split('/').first.split('?').first;
        }
      } catch (_) {}
    }

    final bool isSharedPost =
        msg.isPostShare ||
        (extractedPostId != null && extractedPostId.isNotEmpty);

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
                              : isSharedPost
                              ? InkWell(
                                  onTap: () => _openSharedPost(
                                    extractedPostId!,
                                    extractedPostImageUrl ?? msg.mediaUrl,
                                    extractedPostCaption ?? msg.message,
                                    extractedPostOwnerUsername,
                                    msg.createdAt,
                                  ),
                                  child: SizedBox(
                                    width: 230,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (extractedPostOwnerUsername
                                                ?.isNotEmpty ==
                                            true)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            child: Text(
                                              '@$extractedPostOwnerUsername',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child:
                                              extractedPostImageUrl
                                                      ?.isNotEmpty ==
                                                  true
                                              ? Image.network(
                                                  ApiConstants.getFullUrl(
                                                    extractedPostImageUrl!,
                                                  ),
                                                  width: 230,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        width: 230,
                                                        height: 120,
                                                        color: Colors.black26,
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                            color:
                                                                Colors.white54,
                                                            size: 30,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  width: 230,
                                                  height: 120,
                                                  color: Colors.black26,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.article_outlined,
                                                      color: Colors.white54,
                                                      size: 30,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        if (extractedPostCaption?.isNotEmpty ==
                                                true &&
                                            extractedPostCaption !=
                                                'Sent a post' &&
                                            !extractedPostCaption!.contains(
                                              '/posts/',
                                            )) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            extractedPostCaption,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              height: 1.25,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
          if (isMe && msg.sendError)
            GestureDetector(
              onTap: () => controller.retryMessage(msg),
              child: const Padding(
                padding: EdgeInsets.only(top: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Failed. Tap to retry',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          if (isMe && msg.isPending && !msg.sendError)
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white38,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Sending...',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
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

  Future<void> _openSharedPost(
    String postId,
    String? imageUrl,
    String? caption,
    String? username,
    DateTime createdAt,
  ) async {
    final post = PostModel(
      postId: postId,
      userId: '',
      username: username ?? 'User',
      profileImage: '',
      mediaUrl: imageUrl ?? '',
      mediaType: 'image',
      caption: caption ?? '',
      likesCount: 0,
      commentsCount: 0,
      timestamp: createdAt,
    );
    Get.toNamed('/post-details', arguments: post);
  }

  String _formatLastSeen(dynamic time) {
    if (time == null) return 'Offline';
    try {
      final date = time is DateTime ? time : DateTime.parse(time.toString());
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return 'Last seen ${diff.inDays}d ago';
      if (diff.inHours > 0) return 'Last seen ${diff.inHours}h ago';
      if (diff.inMinutes > 0) return 'Last seen ${diff.inMinutes}m ago';
      return 'Last seen just now';
    } catch (_) {
      return 'Offline';
    }
  }
}
