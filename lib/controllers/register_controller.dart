import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_controller.dart';
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

  // Image handling
  final Rx<File?> selectedLocalImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );

      if (image != null) {
        selectedLocalImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  void removeSelectedImage() {
    selectedLocalImage.value = null;
  }

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.toggle();
  }

  Future<void> register() async {
    if (authController.isLoading.value) return;

    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim().toLowerCase();
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

    if (username.contains(' ')) {
      Get.snackbar('Invalid Username', 'Username cannot contain spaces.');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar('Invalid Email', 'Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      Get.snackbar('Weak Password', 'Password must be at least 6 characters.');
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
      imagePath: selectedLocalImage.value?.path,
    );
    if (success) {
      Get.offAllNamed(AppRoutes.completeProfile);
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
