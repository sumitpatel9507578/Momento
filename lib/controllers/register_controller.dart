import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class RegisterController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.toggle();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      Get.snackbar('Required', 'Please fill all fields.');
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar('Password Error', 'Passwords do not match.');
      return;
    }

    final success = await authController.register(
      name: name,
      username: username,
      email: email,
      password: password,
    );
    if (success) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
