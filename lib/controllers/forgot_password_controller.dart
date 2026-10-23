import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_validators.dart';
import 'auth_controller.dart';

class ForgotPasswordController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  final emailController = TextEditingController();

  final isLoading = false.obs;

  Future<void> sendResetEmail() async {
    final emailError = AppValidators.validateEmail(emailController.text);
    if (emailError != null) {
      Get.snackbar(
        'Invalid Email',
        emailError,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final email = emailController.text.trim();

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
