import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';

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
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
