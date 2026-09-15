import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../repositories/user_repository.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  late Animation<double> fadeAnimation;
  final UserRepository _userRepository = UserRepository();

  @override
  void onInit() {
    super.onInit();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );

    animationController.forward();

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    final apiService = Get.find<ApiService>();
    final token = await apiService.getToken();

    if (token != null) {
      // Verify token with production backend
      print("Splash: Verifying existing token...");
      try {
        final profile = await _userRepository.getMyProfile();

        if (profile != null) {
          print("Splash: Token valid. User: ${profile.username}");
          Get.offAllNamed(AppRoutes.home);
        } else {
          // If profile is null but no 401 was thrown (rare), just go to login
          print("Splash: Profile not found. Redirecting to login.");
          Get.offAllNamed(AppRoutes.login);
        }
      } catch (e) {
        // If ApiService already handled 401, this catch might not even be reached
        // because of Get.offAllNamed, but it's safe to have.
        print("Splash: Auth check failed: $e");
      }
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
