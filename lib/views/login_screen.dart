import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Momento',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 32),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: controller.authController.isLoading.value
                          ? null
                          : () => controller.login(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.authController.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                  child: const Text('Forgot Password?', style: TextStyle(color: AppColors.cyan)),
                ),
                TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.register),
                  child: const Text('Create a new account', style: TextStyle(color: AppColors.cyan)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
