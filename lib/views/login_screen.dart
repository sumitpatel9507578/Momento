import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import '../controllers/network_controller.dart';
import '../routes/app_routes.dart';
import '../utils/api_constants.dart';
import '../utils/app_colors.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final NetworkController networkController = Get.find<NetworkController>();
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.07,
              vertical: size.height * 0.03,
            ),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.06),

                Text(
                  'Momento',
                  style: TextStyle(
                    fontSize: size.width * 0.10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: size.height * 0.01),

                Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: size.width * 0.055,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: size.height * 0.04),

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

                TextField(
                  controller: controller.passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                SizedBox(height: size.height * 0.035),

                Obx(
                  () => Container(
                    width: double.infinity,
                    height: size.height * 0.065,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: controller.authController.isLoading.value
                            ? null
                            : (!networkController.isConnected.value &&
                                  !ApiConstants.useMockData)
                            ? () {
                                Get.snackbar(
                                  'No Internet',
                                  'Please check your internet connection.',
                                );
                              }
                            : () => controller.login(),
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
                              : (!networkController.isConnected.value &&
                                    !ApiConstants.useMockData)
                              ? const Text(
                                  'No Internet',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Text(
                                  'Login',
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
                ),

                SizedBox(height: size.height * 0.025),

                TextButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.forgotPassword);
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppColors.cyan),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () => Get.to(() => const RegisterScreen()),
                  child: const Text(
                    'Create a new account',
                    style: TextStyle(color: AppColors.cyan),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
