import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/explore_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/user_avatar.dart';

class SearchScreen extends GetView<ExploreController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.searchQuery.value.isNotEmpty) {
                  return _buildResults();
                }
                return _buildExplore();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (controller.isLoading.value)
      return const Center(child: CircularProgressIndicator());
    if (controller.searchResults.isEmpty)
      return const Center(
        child: Text('No results', style: TextStyle(color: Colors.white)),
      );

    return ListView.builder(
      itemCount: controller.searchResults.length,
      itemBuilder: (context, index) {
        final user = controller.searchResults[index];
        return ListTile(
          leading: OnlineAvatar(
            userId: user.uid,
            imageUrl: user.profileImage,
            radius: 20,
          ),
          title: Text(user.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '@${user.username}',
            style: const TextStyle(color: Colors.white54),
          ),
          onTap: () => Get.toNamed('/profile', arguments: user.uid),
        );
      },
    );
  }

  Widget _buildExplore() {
    if (controller.isLoadingExplore.value)
      return const Center(child: CircularProgressIndicator());
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: controller.explorePosts.length,
      itemBuilder: (context, index) {
        final post = controller.explorePosts[index];
        return GestureDetector(
          onTap: () => Get.toNamed('/post-details', arguments: post),
          child: Image.network(
            ApiConstants.getFullUrl(post.mediaUrl),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
