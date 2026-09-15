import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/explore_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ExploreController exploreController = Get.put(ExploreController());

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                borderRadius: BorderRadius.circular(16),
                child: TextField(
                  onChanged: (val) => exploreController.searchQuery.value = val,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search Momento...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white54,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ),

            Obx(() {
              if (exploreController.searchQuery.value.isNotEmpty) {
                return _buildSearchResults(exploreController);
              }
              return _buildExploreContent(exploreController, width);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ExploreController controller) {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        if (controller.searchResults.isEmpty) {
          return const Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.searchResults.length,
          itemBuilder: (context, index) {
            final user = controller.searchResults[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surface,
                backgroundImage: user.profileImage.isNotEmpty
                    ? NetworkImage(ApiConstants.getFullUrl(user.profileImage))
                    : null,
                child: user.profileImage.isEmpty
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              title: Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                '@${user.username}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              trailing: Container(
                height: 32,
                child: ElevatedButton(
                  onPressed: () => controller.toggleFollow(user.uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isFollowing
                        ? Colors.white10
                        : AppColors.purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: user.isFollowing
                            ? Colors.white24
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Text(
                    user.isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              onTap: () => Get.toNamed('/profile', arguments: user.uid),
            );
          },
        );
      }),
    );
  }

  Widget _buildExploreContent(ExploreController controller, double width) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          controller.loadSuggestions();
          controller.fetchExplorePosts();
        },
        color: AppColors.purple,
        child: CustomScrollView(
          slivers: [
            // Suggested Users
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Suggested for you',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 130,
                    child: Obx(
                      () => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        itemCount: controller.suggestedUsers.length,
                        itemBuilder: (context, index) {
                          final user = controller.suggestedUsers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundImage: user.profileImage.isNotEmpty
                                      ? NetworkImage(
                                          ApiConstants.getFullUrl(
                                            user.profileImage,
                                          ),
                                        )
                                      : null,
                                  child: user.profileImage.isEmpty
                                      ? const Icon(Icons.person, size: 30)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '@${user.username}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () =>
                                      controller.toggleFollow(user.uid),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.isFollowing
                                          ? Colors.white10
                                          : AppColors.purple.withValues(
                                              alpha: 0.2,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: user.isFollowing
                                            ? Colors.white24
                                            : AppColors.purple.withValues(
                                                alpha: 0.3,
                                              ),
                                      ),
                                    ),
                                    child: Text(
                                      user.isFollowing ? 'Following' : 'Follow',
                                      style: TextStyle(
                                        color: user.isFollowing
                                            ? Colors.white70
                                            : AppColors.purple,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Explore Grid Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Explore Moments',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Explore Grid
            Obx(() {
              if (controller.isLoadingExplore.value &&
                  controller.explorePosts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppColors.purple),
                    ),
                  ),
                );
              }

              if (controller.explorePosts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: Text(
                        'No moments to explore yet ✨',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = controller.explorePosts[index];
                    return GestureDetector(
                      onTap: () =>
                          Get.toNamed('/post-details', arguments: post),
                      child: Image.network(
                        ApiConstants.getFullUrl(post.mediaUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    );
                  }, childCount: controller.explorePosts.length),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}
