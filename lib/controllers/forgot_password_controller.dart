import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class ForgotPasswordController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  final emailController = TextEditingController();

  final isLoading = false.obs;

  Future<void> sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar('Required', 'Please enter your email address.');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar('Invalid Email', 'Please enter a valid email address.');
      return;
    }

    try {
      isLoading.value = true;

      await authController.forgotPassword(email);

      Get.snackbar(
        'Email Sent',
        'Check your inbox for the password reset email.',
        duration: const Duration(seconds: 4),
      );

      emailController.clear();
    } catch (_) {
      // AuthController already handles the error message.
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
