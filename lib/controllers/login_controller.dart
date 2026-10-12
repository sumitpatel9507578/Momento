import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';

class LoginController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    final success = await authController.login(
      email: email,
      password: password,
    );

    if (success) {
      final apiService = Get.find<ApiService>();
      final user = await apiService.getUser();
      final bio = user?['bio']?.toString().trim() ?? '';

      // If bio is empty, assume profile is not completed yet
      if (bio.isEmpty) {
        Get.offAllNamed(AppRoutes.completeProfile);
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    }
  }

  Future<void> loginWithGoogle() async {
    final success = await authController.loginWithGoogle();

    if (success) {
      final apiService = Get.find<ApiService>();
      final user = await apiService.getUser();
      final bio = user?['bio']?.toString().trim() ?? '';

      // If bio is empty, assume profile is not completed yet
      if (bio.isEmpty) {
        Get.offAllNamed(AppRoutes.completeProfile);
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
