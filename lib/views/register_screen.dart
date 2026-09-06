import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/network_controller.dart';
import '../controllers/register_controller.dart';
import '../utils/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final NetworkController networkController = Get.find<NetworkController>();
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.07,
              vertical: size.height * 0.02,
            ),
            child: Column(
              children: [
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: size.width * 0.08,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  'Join Momento today',
                  style: TextStyle(
                    fontSize: size.width * 0.045,
                    color: AppColors.grey,
                  ),
                ),
                SizedBox(height: size.height * 0.04),

                TextField(
                  controller: controller.nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                TextField(
                  controller: controller.usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                TextField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                Obx(
                  () => TextField(
                    controller: controller.passwordController,
                    obscureText: controller.obscurePassword.value,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscurePassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.grey,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                Obx(
                  () => TextField(
                    controller: controller.confirmPasswordController,
                    obscureText: controller.obscureConfirmPassword.value,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscureConfirmPassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.grey,
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.04),

                Obx(
                  () => Container(
                    width: double.infinity,
                    height: size.height * 0.065,
                    decoration: BoxDecoration(
                      gradient: networkController.isConnected.value
                          ? AppColors.primaryGradient
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade800,
                                Colors.grey.shade700,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: controller.authController.isLoading.value
                          ? null
                          : !networkController.isConnected.value
                          ? () {
                              Get.snackbar(
                                'No Internet',
                                'Please check your internet connection.',
                              );
                            }
                          : () => controller.register(),
                      child: Center(
                        child: controller.authController.isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : !networkController.isConnected.value
                            ? const Text(
                                'No Internet',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.025),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.grey),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
