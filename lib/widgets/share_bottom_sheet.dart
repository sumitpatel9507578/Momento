import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class ShareBottomSheet extends StatefulWidget {
  final String? contentUrl;
  const ShareBottomSheet({super.key, this.contentUrl});

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final ChatController chatController = Get.isRegistered<ChatController>()
      ? Get.find<ChatController>()
      : Get.put(ChatController(), fenix: true);

  final ApiService apiService = Get.find<ApiService>();
  final RxList<Map<String, dynamic>> friends = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      isLoading.value = true;
      final response = await apiService.get(ApiConstants.users);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['users'] ?? [];
        final currentId = await apiService.getUserId();

        friends.assignAll(
          list
              .where(
                (u) =>
                    (u['id'] ?? u['uid'] ?? u['_id']).toString() != currentId,
              )
              .map(
                (u) => {
                  'id': (u['id'] ?? u['uid'] ?? u['_id']).toString(),
                  'name': u['name'] ?? u['full_name'] ?? 'User',
                  'username': u['username'] ?? '',
                  'image': u['profileImage'] ?? u['profile_image'] ?? '',
                },
              )
              .toList(),
        );
      }
    } catch (e) {
      print("Error loading friends for share: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final platforms = [
      {
        'name': 'WhatsApp',
        'icon': Icons.chat_bubble_rounded,
        'color': Colors.green,
      },
      {
        'name': 'Messenger',
        'icon': Icons.message_rounded,
        'color': Colors.blue,
      },
      {'name': 'Twitter', 'icon': Icons.tag_rounded, 'color': Colors.lightBlue},
      {'name': 'Copy Link', 'icon': Icons.link_rounded, 'color': Colors.grey},
      {
        'name': 'More',
        'icon': Icons.more_horiz_rounded,
        'color': AppColors.purple,
      },
    ];

    return GlassContainer(
      height: size.height * 0.55,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Share to',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),

          // Platforms Row
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: platforms.length,
              itemBuilder: (context, index) {
                final p = platforms[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: (p['color'] as Color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          p['icon'] as IconData,
                          color: p['color'] as Color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p['name'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Send in Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Friends List for Direct Chat Sharing
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.purple,
                    strokeWidth: 2,
                  ),
                );
              }
              if (friends.isEmpty) {
                return const Center(
                  child: Text(
                    'No friends found',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final imageUrl = friend['image'] ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(ApiConstants.getFullUrl(imageUrl))
                          : null,
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    title: Text(
                      friend['name'] ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '@${friend['username']}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final text = widget.contentUrl != null
                            ? 'Check out this post/reel: ${ApiConstants.getFullUrl(widget.contentUrl)}'
                            : 'Hey!';
                        final success = await chatController.sendMessage(
                          friend['id'],
                          text,
                        );
                        Get.back();
                        if (success) {
                          Get.snackbar('Success', 'Sent to ${friend['name']}!');
                        } else {
                          Get.snackbar('Error', 'Failed to send message');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        minimumSize: const Size(70, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
