import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/chat_controller.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';
import 'user_avatar.dart';

class ShareBottomSheet extends StatefulWidget {
  final String? contentUrl;
  final String? reelId;
  final String? postId;
  final String? postCaption;
  final String? postOwnerUsername;
  const ShareBottomSheet({
    super.key,
    this.contentUrl,
    this.reelId,
    this.postId,
    this.postCaption,
    this.postOwnerUsername,
  });

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final ChatController chatController = Get.isRegistered<ChatController>()
      ? Get.find<ChatController>()
      : Get.put(ChatController());

  final ApiService apiService = Get.find<ApiService>();
  final RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = true.obs;
  final RxMap<String, bool> sendingMap = <String, bool>{}.obs;
  final RxMap<String, bool> sentMap = <String, bool>{}.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      isLoading.value = true;
      var response = await apiService.get("${ApiConstants.users}/search?q=");
      if (response.statusCode != 200) {
        response = await apiService.get(ApiConstants.users);
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['users'] ?? [];
        final currentId = await apiService.getUserId();

        final parsed = list
            .where(
              (u) => (u['id'] ?? u['uid'] ?? u['_id']).toString() != currentId,
            )
            .map(
              (u) => {
                'id': (u['id'] ?? u['uid'] ?? u['_id']).toString(),
                'name': u['name'] ?? u['full_name'] ?? 'User',
                'username': u['username'] ?? '',
                'image': u['profileImage'] ?? u['profile_image'] ?? '',
              },
            )
            .toList();

        friends.assignAll(parsed);
      }
    } catch (e) {
      debugPrint("Error loading friends for share: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _onSearchChanged(String query) async {
    searchQuery.value = query;
    final q = query.trim();
    if (q.isEmpty) return;

    try {
      final response = await apiService.get(
        "${ApiConstants.searchUsers}?q=${Uri.encodeComponent(q)}",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['users'] ?? [];
        final currentId = await apiService.getUserId();

        final searchResults = list
            .where(
              (u) => (u['id'] ?? u['uid'] ?? u['_id']).toString() != currentId,
            )
            .map(
              (u) => {
                'id': (u['id'] ?? u['uid'] ?? u['_id']).toString(),
                'name': u['name'] ?? u['full_name'] ?? 'User',
                'username': u['username'] ?? '',
                'image': u['profileImage'] ?? u['profile_image'] ?? '',
              },
            )
            .toList();

        for (final user in searchResults) {
          final exists = friends.any((f) => f['id'] == user['id']);
          if (!exists) {
            friends.add(user);
          }
        }
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get displayFriends {
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return friends;
    return friends.where((u) {
      final name = u['name']?.toString().toLowerCase() ?? '';
      final username = u['username']?.toString().toLowerCase() ?? '';
      return name.contains(q) || username.contains(q);
    }).toList();
  }

  void _handlePlatformShare(String platformName) async {
    final lowerName = platformName.toLowerCase();

    // Share to Momento Story / Status -> Open Story Editor Panel First
    if (lowerName.contains('story') || lowerName.contains('status')) {
      Get.back(); // Dismiss share bottom sheet

      String mediaUrl = widget.contentUrl ?? '';
      if (mediaUrl.isEmpty && widget.postId != null) {
        mediaUrl = widget.contentUrl ?? '';
      }

      final isVideo =
          mediaUrl.toLowerCase().contains('.mp4') ||
          mediaUrl.toLowerCase().contains('.mov');

      Get.toNamed(
        AppRoutes.storyEditor,
        arguments: {
          'mediaPath': mediaUrl,
          'mediaType': isVideo ? 'video' : 'image',
          'contentType': 'story',
          'caption': widget.postCaption ?? '',
        },
      );
      return;
    }

    String shareUrl = '';
    if (widget.contentUrl != null && widget.contentUrl!.isNotEmpty) {
      shareUrl = ApiConstants.getFullUrl(widget.contentUrl!);
    } else if (widget.reelId != null && widget.reelId!.isNotEmpty) {
      shareUrl = ApiConstants.getFullUrl('/reels/${widget.reelId}');
    } else if (widget.postId != null && widget.postId!.isNotEmpty) {
      shareUrl = ApiConstants.getFullUrl('/posts/${widget.postId}');
    } else {
      shareUrl = 'https://momento.app';
    }

    if (platformName == 'Copy Link' || platformName == 'Copy link') {
      await Clipboard.setData(ClipboardData(text: shareUrl));
      Get.snackbar(
        'Share',
        'Link copied to clipboard!',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await Share.share('Check out this content on Momento: $shareUrl');
    } catch (_) {
      Clipboard.setData(ClipboardData(text: shareUrl));
      Get.snackbar(
        '$platformName Share',
        'Link copied to clipboard!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _sendToFriend(String friendId, String friendName) async {
    if (sendingMap[friendId] == true || sentMap[friendId] == true) return;
    sendingMap[friendId] = true;

    final text = (widget.reelId != null && widget.reelId!.isNotEmpty)
        ? 'Shared a reel'
        : (widget.postId != null && widget.postId!.isNotEmpty)
        ? 'Sent a post'
        : (widget.contentUrl != null && widget.contentUrl!.isNotEmpty)
        ? 'Check out this post: ${ApiConstants.getFullUrl(widget.contentUrl!)}'
        : 'Hey!';

    final success = await chatController.sendMessage(
      friendId,
      text,
      reelId: widget.reelId,
      postId: widget.postId,
      postImageUrl: widget.contentUrl,
      postCaption: widget.postCaption,
      postOwnerUsername: widget.postOwnerUsername,
      messageTypeOverride: (widget.postId != null && widget.postId!.isNotEmpty)
          ? 'post'
          : null,
    );

    sendingMap[friendId] = false;
    if (success) {
      sentMap[friendId] = true;
      Get.snackbar(
        'Success',
        'Sent to $friendName!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final platforms = [
      {
        'name': 'Add to story',
        'icon': Icons.add_circle_outline_rounded,
        'color': Colors.white,
      },
      {'name': 'Copy link', 'icon': Icons.link_rounded, 'color': Colors.white},
      {
        'name': 'WhatsApp',
        'icon': Icons.chat_bubble_rounded,
        'color': Colors.green,
      },
      {'name': 'Share', 'icon': Icons.share_rounded, 'color': Colors.white},
      {
        'name': 'Status',
        'icon': Icons.donut_large_rounded,
        'color': Colors.greenAccent,
      },
    ];

    return GlassContainer(
      height: size.height * 0.78,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13.5,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white38,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Friends Grid (3 Columns Instagram style)
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.purple,
                    strokeWidth: 2,
                  ),
                );
              }

              final currentFriends = displayFriends;

              if (currentFriends.isEmpty) {
                return const Center(
                  child: Text(
                    'No friends found',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: currentFriends.length,
                itemBuilder: (context, index) {
                  final friend = currentFriends[index];
                  final friendId = friend['id'].toString();
                  final imageUrl = friend['image'] ?? '';
                  final name = friend['name'] ?? 'User';

                  return Obx(() {
                    final isSending = sendingMap[friendId] == true;
                    final isSent = sentMap[friendId] == true;

                    return GestureDetector(
                      onTap: () => _sendToFriend(friendId, name),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              UserAvatar(
                                userId: friendId,
                                imageUrl: imageUrl,
                                radius: 32,
                                backgroundColor: AppColors.darkGrey,
                              ),
                              if (isSent)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              if (isSending)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                },
              );
            }),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Bottom Horizontal Actions (Add to story, Copy link, WhatsApp, Share, Status)
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: platforms.length,
              itemBuilder: (context, index) {
                final p = platforms[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: InkWell(
                    onTap: () => _handlePlatformShare(p['name'] as String),
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Icon(
                            p['icon'] as IconData,
                            color: p['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p['name'] as String,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
