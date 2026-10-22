import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:momento/controllers/auth_controller.dart';
import 'package:momento/routes/app_routes.dart';
import 'package:momento/utils/app_validators.dart';

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

    final nameError = AppValidators.validateName(nameController.text);
    if (nameError != null) {
      Get.snackbar(
        'Invalid Name',
        nameError,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final usernameError = AppValidators.validateUsername(
      usernameController.text,
    );
    if (usernameError != null) {
      Get.snackbar(
        'Invalid Username',
        usernameError,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final emailError = AppValidators.validateEmail(emailController.text);
    if (emailError != null) {
      Get.snackbar(
        'Invalid Email',
        emailError,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final passwordError = AppValidators.validatePassword(
      passwordController.text,
    );
    if (passwordError != null) {
      Get.snackbar(
        'Weak Password',
        passwordError,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Password Error',
        'Passwords do not match.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

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
