import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/forgot_password_controller.dart';
import '../utils/app_colors.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final ForgotPasswordController controller =
      Get.find<ForgotPasswordController>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.07,
            vertical: size.height * 0.04,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset your password',
                style: TextStyle(
                  fontSize: size.width * 0.075,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: size.height * 0.012),

              Text(
                'Enter the email connected to your Momento account. '
                'We will send you a password reset email.',
                style: TextStyle(
                  fontSize: size.width * 0.038,
                  height: 1.5,
                  color: AppColors.grey,
                ),
              ),

              SizedBox(height: size.height * 0.04),

              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              SizedBox(height: size.height * 0.03),

              Obx(
                () => GestureDetector(
                  onTap: controller.isLoading.value
                      ? null
                      : controller.sendResetEmail,
                  child: Container(
                    width: double.infinity,
                    height: size.height * 0.065,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Send Reset Email',
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

              SizedBox(height: size.height * 0.02),

              Center(
                child: TextButton(
                  onPressed: Get.back,
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(color: AppColors.cyan),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
