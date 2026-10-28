import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/note_controller.dart';
import '../controllers/profile_controller.dart';
import 'package:momento/models/note_model.dart';
import '../utils/app_colors.dart';
import '../widgets/note_bubble_widget.dart';
import '../widgets/note_create_sheet.dart';
import '../widgets/user_avatar.dart';

class ChatListScreen extends GetView<ChatController> {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NoteController noteController = Get.isRegistered<NoteController>()
        ? Get.find<NoteController>()
        : Get.put(NoteController());

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

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchConversations();
            await noteController.loadNotes();
          },
          color: AppColors.purple,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top Notes Status Bar (Instagram Style 24h Thought Bubbles)
              SliverToBoxAdapter(
                child: _buildNotesBar(context, controller, noteController),
              ),

              if (controller.conversations.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.5,
                            ),
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
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final convo = controller.conversations[index];
                    final profileImage =
                        convo['profile_image'] ?? convo['profileImage'];
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

                    return InkWell(
                      onTap: () => Get.toNamed('/chat', arguments: convo),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            OnlineAvatar(
                              userId: conversationUserId,
                              imageUrl: profileImage,
                              radius: 29,
                              backgroundColor: AppColors.darkGrey,
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
                                      color: isUnread
                                          ? Colors.white
                                          : Colors.white38,
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
                  }, childCount: controller.conversations.length),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNotesBar(
    BuildContext context,
    ChatController controller,
    NoteController noteController,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Obx(() {
        final myNote = noteController.myNote;
        final friendsNotes = noteController.friendsNotes;
        final profileCtrl = Get.isRegistered<ProfileController>(tag: 'me')
            ? Get.find<ProfileController>(tag: 'me')
            : null;
        final myImage = profileCtrl?.currentUser.value?.profileImage;

        return SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: friendsNotes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return NoteBubbleWidget(
                  note: myNote,
                  isMine: true,
                  myProfileImage: myImage,
                  onTap: () {
                    NoteCreateSheet.show(
                      context,
                      currentNote: myNote,
                      profileImage: myImage,
                    );
                  },
                );
              }

              final note = friendsNotes[index - 1];
              return NoteBubbleWidget(
                note: note,
                isMine: false,
                onTap: () {
                  _showNoteReplyDialog(context, note, controller);
                },
              );
            },
          ),
        );
      }),
    );
  }

  void _showNoteReplyDialog(
    BuildContext context,
    NoteModel note,
    ChatController chatController,
  ) {
    final replyTextController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar + Floating Thought Bubble
              Stack(
                alignment: Alignment.center,
                children: [
                  UserAvatar(
                    userId: note.userId,
                    imageUrl: note.profileImage,
                    radius: 36,
                    backgroundColor: AppColors.darkGrey,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Note Thought Bubble Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '"${note.noteText}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              if (note.musicTrack != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      color: AppColors.purple,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${note.musicTrack!['title'] ?? 'Song'} • ${note.musicTrack!['artist'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 18),

              // Quick DM Reply Field
              TextField(
                controller: replyTextController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Reply to ${note.username}...',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13.5,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final text = replyTextController.text.trim();
                      if (text.isNotEmpty) {
                        Get.back();
                        await chatController.sendMessage(
                          note.userId,
                          'Replied to note "${note.noteText}": $text',
                        );
                        Get.snackbar(
                          'Sent',
                          'Reply sent to ${note.username}',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Send DM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitleText(Map<String, dynamic> convo) {
    final messageType = convo['messageType'] ?? convo['message_type'];
    final rawMsg = convo['lastMessage'] ?? convo['message'];
    String msg = rawMsg?.toString() ?? 'Tap to chat';
    if (messageType == 'reel') {
      msg = 'Shared a reel';
    } else if (messageType == 'post') {
      msg = 'Sent a post';
    } else if (messageType == 'image') {
      msg = 'Sent a photo';
    }
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
