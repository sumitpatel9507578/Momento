import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class ShareBottomSheet extends StatefulWidget {
  final String? contentUrl;
  final String? reelId;
  const ShareBottomSheet({super.key, this.contentUrl, this.reelId});

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
      final response = await apiService.get(ApiConstants.users);
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
      print("Error loading friends for share: $e");
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
      height: size.height * 0.72,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Share to',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          // Platforms Row
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: platforms.length,
              itemBuilder: (context, index) {
                final p = platforms[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (p['color'] as Color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          p['icon'] as IconData,
                          color: p['color'] as Color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['name'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 4),

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
          const SizedBox(height: 6),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white38,
                  size: 18,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Friends List for Direct Chat Sharing
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

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: currentFriends.length,
                itemBuilder: (context, index) {
                  final friend = currentFriends[index];
                  final imageUrl = friend['image'] ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(ApiConstants.getFullUrl(imageUrl))
                          : null,
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.person, size: 18)
                          : null,
                    ),
                    title: Text(
                      friend['name'] ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '@${friend['username']}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final text = widget.reelId != null
                            ? 'Shared a reel'
                            : widget.contentUrl != null
                            ? 'Check out this post: ${ApiConstants.getFullUrl(widget.contentUrl)}'
                            : 'Hey!';
                        final success = await chatController.sendMessage(
                          friend['id'],
                          text,
                          reelId: widget.reelId,
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
                        minimumSize: const Size(64, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(color: Colors.white, fontSize: 11.5),
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
