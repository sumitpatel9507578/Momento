import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';

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

      final success = await authController.forgotPassword(email);

      if (success) {
        emailController.clear();
      }
    } catch (_) {
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
