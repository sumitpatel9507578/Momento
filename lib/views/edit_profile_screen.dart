import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/edit_profile_controller.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  final EditProfileController controller = Get.find<EditProfileController>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Edit Profile'),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isSaving.value
                  ? null
                  : controller.saveProfile,
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.025,
          ),
          child: Column(
            children: [
              Obx(() {
                final image = controller.selectedImage.value;

                return Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: size.width * 0.30,
                      height: size.width * 0.30,
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        backgroundImage: _getImageProvider(image),
                        child: _getImageProvider(image) == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 55,
                              )
                            : null,
                      ),
                    ),

                    GestureDetector(
                      onTap: controller.pickProfileImage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          border: Border.all(
                            color: AppColors.background,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ],
                );
              }),

              SizedBox(height: size.height * 0.015),

              TextButton(
                onPressed: controller.pickProfileImage,
                child: const Text(
                  'Change Profile Photo',
                  style: TextStyle(color: AppColors.cyan),
                ),
              ),

              Obx(
                () => controller.selectedImage.value != null
                    ? TextButton(
                        onPressed: controller.removeSelectedImage,
                        child: const Text(
                          'Remove Selected Photo',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              SizedBox(height: size.height * 0.025),

              GlassContainer(
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  children: [
                    TextField(
                      controller: controller.nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    TextField(
                      controller: controller.usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Username',
                        prefixIcon: Icon(Icons.people_rounded),
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    TextField(
                      controller: controller.bioController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Bio',
                        prefixIcon: Icon(Icons.edit_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.03),

              Obx(
                () => GestureDetector(
                  onTap: controller.isSaving.value
                      ? null
                      : controller.saveProfile,
                  child: Container(
                    width: double.infinity,
                    height: size.height * 0.065,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
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
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider<Object>? _getImageProvider(File? image) {
    if (image != null) {
      return FileImage(image);
    }

    final user = controller.profileController.currentUser.value;

    if (user != null &&
        user.profileImage.isNotEmpty &&
        !user.profileImage.startsWith('/')) {
      return NetworkImage(user.profileImage);
    }

    return null;
  }
}
