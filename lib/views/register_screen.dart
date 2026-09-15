import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:momento/controllers/network_controller.dart';
import 'package:momento/controllers/register_controller.dart';
import 'package:momento/utils/api_constants.dart';
import 'package:momento/utils/app_colors.dart';

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NetworkController networkController = Get.find<NetworkController>();
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
                SizedBox(height: size.height * 0.03),

                // Dynamic Profile Image Picker
                GestureDetector(
                  onTap: () => _showImagePickerOptions(context),
                  child: Obx(
                    () => Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: CircleAvatar(
                            backgroundColor: AppColors.surface,
                            backgroundImage:
                                controller.selectedLocalImage.value != null
                                ? FileImage(
                                        controller.selectedLocalImage.value!,
                                      )
                                      as ImageProvider
                                : (controller
                                          .profileImagePreview
                                          .value
                                          .isNotEmpty
                                      ? NetworkImage(
                                          controller.profileImagePreview.value,
                                        )
                                      : null),
                            child:
                                controller.selectedLocalImage.value == null &&
                                    controller.profileImagePreview.value.isEmpty
                                ? const Icon(
                                    Icons.person_add_alt_1_outlined,
                                    color: Colors.white24,
                                    size: 40,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              controller.selectedLocalImage.value != null
                                  ? Icons.edit_rounded
                                  : Icons.add_a_photo_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.03),

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
                      gradient:
                          (networkController.isConnected.value ||
                              ApiConstants.useMockData)
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
                          : (!networkController.isConnected.value &&
                                !ApiConstants.useMockData)
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

  void _showImagePickerOptions(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerBtn(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Get.back();
                    controller.pickImage(ImageSource.camera);
                  },
                ),
                _buildPickerBtn(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Get.back();
                    controller.pickImage(ImageSource.gallery);
                  },
                ),
                if (controller.selectedLocalImage.value != null)
                  _buildPickerBtn(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove',
                    color: Colors.redAccent,
                    onTap: () {
                      Get.back();
                      controller.removeSelectedImage();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? AppColors.purple).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? AppColors.purple, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
