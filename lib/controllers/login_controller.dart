import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/auth_controller.dart';
import 'package:momento/routes/app_routes.dart';
import 'package:momento/services/api_service.dart';

class LoginController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter your email and password',
        snackPosition: SnackPosition.BOTTOM,
      );
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
