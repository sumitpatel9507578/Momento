import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/reel_controller.dart';
import '../routes/app_routes.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatController chatController = Get.isRegistered<ChatController>()
      ? Get.find<ChatController>()
      : Get.put(ChatController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    chatController.fetchSavedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Saved Items',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.purple,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: [
            Tab(
              child: Obx(
                () => Text('Posts (${chatController.savedPosts.length})'),
              ),
            ),
            Tab(
              child: Obx(
                () => Text('Reels (${chatController.savedReelsList.length})'),
              ),
            ),
            Tab(
              child: Obx(
                () => Text('Messages (${chatController.savedMessages.length})'),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Saved Posts
          Obx(() {
            if (chatController.isLoadingSaved.value &&
                chatController.savedPosts.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              );
            }

            final savedPosts = chatController.savedPosts;

            if (chatController.savedItemsError.isNotEmpty &&
                savedPosts.isEmpty) {
              return _buildErrorState(chatController.savedItemsError.value);
            }

            if (savedPosts.isEmpty) {
              return _buildEmptyState(
                'No saved posts yet',
                Icons.bookmark_border_rounded,
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: savedPosts.length,
              itemBuilder: (context, index) {
                final post = savedPosts[index];
                return Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () =>
                            Get.toNamed('/post-details', arguments: post),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            ApiConstants.getFullUrl(post.mediaUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.surface,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.white38,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: Obx(() {
                          final isSaving = chatController.savingPostIds
                              .contains(post.postId);
                          return IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: isSaving
                                ? null
                                : () => chatController.toggleSavePost(
                                    post.postId,
                                    isSaved: true,
                                  ),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.bookmark_remove,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            );
          }),

          // 2. Saved Reels
          Obx(() {
            if (chatController.isLoadingSaved.value &&
                chatController.savedReelsList.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              );
            }

            final reels = chatController.savedReelsList;

            if (chatController.savedItemsError.isNotEmpty && reels.isEmpty) {
              return _buildErrorState(chatController.savedItemsError.value);
            }

            if (reels.isEmpty) {
              return _buildEmptyState(
                'No saved reels yet',
                Icons.movie_outlined,
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.6,
              ),
              itemCount: reels.length,
              itemBuilder: (context, index) {
                final reel = reels[index];
                final reelId =
                    (reel['id'] ?? reel['reelId'] ?? reel['_id'] ?? '')
                        .toString();

                return Stack(
                  children: [
                    Positioned.fill(
                      child: InkWell(
                        onTap: () => _openSavedReel(reelId),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            color: AppColors.surface,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white70,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    (reel['caption'] ?? 'Saved reel')
                                        .toString(),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: Obx(() {
                          final isSaving = chatController.savingReelIds
                              .contains(reelId);
                          return IconButton(
                            padding: EdgeInsets.zero,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.bookmark_remove,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                            onPressed: isSaving
                                ? null
                                : () => chatController.toggleSaveReel(
                                    reelId,
                                    isSaved: true,
                                  ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            );
          }),

          // 3. Saved Messages
          Obx(() {
            if (chatController.isLoadingSaved.value &&
                chatController.savedMessages.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              );
            }

            final msgs = chatController.savedMessages;

            if (chatController.savedItemsError.isNotEmpty && msgs.isEmpty) {
              return _buildErrorState(chatController.savedItemsError.value);
            }

            if (msgs.isEmpty) {
              return _buildEmptyState(
                'No saved messages yet',
                Icons.chat_bubble_outline_rounded,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: msgs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final msg = msgs[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: msg.conversationUserId == null
                              ? null
                              : () => Get.toNamed(
                                  AppRoutes.chat,
                                  arguments: {
                                    'id': msg.conversationUserId,
                                    'username': msg.conversationUsername,
                                    'full_name': msg.conversationName,
                                    'profile_image':
                                        msg.conversationProfileImage,
                                  },
                                ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.messageType == 'reel'
                                    ? (msg.reelCaption?.isNotEmpty == true
                                          ? 'Shared reel: ${msg.reelCaption}'
                                          : 'Shared a reel')
                                    : msg.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                msg.conversationName == null
                                    ? _formatDate(msg.createdAt)
                                    : 'Conversation with ${msg.conversationName}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Obx(() {
                        final isSaving = chatController.savingMessageIds
                            .contains(msg.id);
                        return IconButton(
                          onPressed: isSaving
                              ? null
                              : () => chatController.toggleSaveMessage(msg),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.bookmark_remove,
                                  color: AppColors.purple,
                                  size: 22,
                                ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: chatController.fetchSavedItems,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSavedReel(String reelId) async {
    if (reelId.isEmpty) {
      Get.snackbar('Unavailable', 'This saved reel has no valid ID');
      return;
    }
    final reelController = Get.isRegistered<ReelController>()
        ? Get.find<ReelController>()
        : Get.put(ReelController());
    if (await reelController.openReel(reelId)) {
      Get.toNamed(AppRoutes.reels, arguments: reelId);
    }
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 56),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
