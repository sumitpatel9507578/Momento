import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/find_people_controller.dart';
import '../utils/api_constants.dart';
import '../widgets/user_avatar.dart';

class FindPeopleScreen extends StatelessWidget {
  FindPeopleScreen({super.key});

  final FindPeopleController controller = Get.put(FindPeopleController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08080D),
        foregroundColor: Colors.white,
        title: const Text('Find People'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Connect with people',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Follow people you know or discover new creators.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF11111A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => controller.searchUsers(value),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.users.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  );
                }

                if (controller.users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.users.length,
                  itemBuilder: (context, index) {
                    final user = controller.users[index];
                    final String imageUrl = user['image'] ?? '';
                    final String targetUserId =
                        (user['uid'] ?? user['id'] ?? user['_id'] ?? '')
                            .toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11111A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          OnlineAvatar(
                            userId: targetUserId,
                            imageUrl: imageUrl,
                            radius: 28,
                            backgroundColor: const Color(0xFF7C3AED),
                            onTap: targetUserId.isNotEmpty
                                ? () => Get.toNamed(
                                    '/profile',
                                    arguments: targetUserId,
                                  )
                                : null,
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: GestureDetector(
                              onTap: targetUserId.isNotEmpty
                                  ? () => Get.toNamed(
                                      '/profile',
                                      arguments: targetUserId,
                                    )
                                  : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name']?.toString() ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${user['username']}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Obx(() {
                            final followed =
                                controller.users[index]['isFollowed']
                                    as bool? ??
                                false;
                            final isLoading =
                                controller.users[index]['isLoading'] as bool? ??
                                false;

                            return OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => controller.toggleFollow(index),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: followed
                                    ? Colors.white54
                                    : Colors.white,
                                side: BorderSide(
                                  color: followed
                                      ? Colors.white24
                                      : const Color(0xFF8B5CF6),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white54,
                                      ),
                                    )
                                  : Text(followed ? 'Following' : 'Follow'),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.continueToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Continue to Momento',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
