import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/network_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import 'create_post_screen.dart';
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
      const SearchScreen(),
      const CreatePostScreen(),
      const ReelsScreen(),
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

          // Global Offline Banner
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
      bottomNavigationBar: Obx(
        () => Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(top: BorderSide(color: Colors.white10, width: 0.3)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    0,
                    Icons.home_filled,
                    Icons.home_outlined,
                    controller,
                  ),
                  _buildNavItem(1, Icons.search, Icons.search, controller),
                  _buildCreatePostNavItem(2, controller),
                  _buildNavItem(
                    3,
                    Icons.play_circle_fill,
                    Icons.play_circle_outline,
                    controller,
                  ),
                  _buildProfileNavItem(4, controller),
                ],
              ),
            ),
          ),
        ),
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
      onPressed: () => controller.changeTab(index),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      icon: Icon(
        isSelected ? activeIcon : inactiveIcon,
        size: 28,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCreatePostNavItem(int index, HomeController controller) {
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
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
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1,
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
