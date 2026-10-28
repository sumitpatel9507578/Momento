import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/mini_player_widget.dart';

import '../controllers/chat_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/network_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/api_constants.dart';
import 'chat_list_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'reels_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    final List<Widget> screens = [
      const HomeScreen(),
      const ReelsScreen(),
      const ChatListScreen(),
      const SearchScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Obx(
            () => IndexedStack(
              index: controller.currentIndex.value,
              children: screens,
            ),
          ),

          Obx(() {
            final networkController = Get.find<NetworkController>();
            if (networkController.isConnected.value) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  child: const Center(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerWidget(),
          Obx(
            () => Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.white10, width: 0.3),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 1. Home
                      _buildNavItem(
                        0,
                        Icons.home_filled,
                        Icons.home_outlined,
                        controller,
                      ),
                      // 2. Reels
                      _buildNavItem(
                        1,
                        Icons.play_circle_fill,
                        Icons.play_circle_outline,
                        controller,
                      ),
                      // 3. Messages / Direct Chat List Tab
                      _buildMessagesNavItem(controller),
                      // 4. Search
                      _buildNavItem(3, Icons.search, Icons.search, controller),
                      // 5. Profile
                      _buildProfileNavItem(4, controller),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    HomeController controller,
  ) {
    final isSelected = controller.currentIndex.value == index;
    return IconButton(
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      onPressed: () => controller.changeTab(index),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      icon: Icon(
        isSelected ? activeIcon : inactiveIcon,
        size: 26,
        color: isSelected ? AppColors.purple : Colors.white,
      ),
    );
  }

  Widget _buildMessagesNavItem(HomeController controller) {
    final isSelected = controller.currentIndex.value == 2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.changeTab(2),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.send_rounded,
            size: 24,
            color: isSelected ? AppColors.purple : Colors.white,
          ),
          Obx(() {
            final chatController = Get.isRegistered<ChatController>()
                ? Get.find<ChatController>()
                : null;
            final count = chatController?.totalUnreadCount ?? 0;
            if (count <= 0) return const SizedBox.shrink();

            final badgeText = count > 99 ? '99+' : '$count';
            return Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                child: Text(
                  badgeText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProfileNavItem(int index, HomeController controller) {
    final isSelected = controller.currentIndex.value == index;
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.purple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Obx(() {
          final user = Get.find<ProfileController>(tag: 'me').currentUser.value;
          return CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey[900],
            backgroundImage: user != null && user.profileImage.isNotEmpty
                ? NetworkImage(ApiConstants.getFullUrl(user.profileImage))
                : null,
            child: user == null || user.profileImage.isEmpty
                ? const Icon(Icons.person, size: 18, color: Colors.white)
                : null,
          );
        }),
      ),
    );
  }
}
