import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/complete_profile_controller.dart';

class CompleteProfileScreen extends StatelessWidget {
  CompleteProfileScreen({super.key});

  final CompleteProfileController controller = Get.put(
    CompleteProfileController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Tell people a little about yourself.',
                style: TextStyle(color: Colors.white60, fontSize: 15),
              ),

              const SizedBox(height: 35),

              Center(
                child: GestureDetector(
                  onTap: controller.pickProfileImage,
                  child: Obx(() {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF11111A),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6),
                          width: 2,
                        ),
                        image: controller.selectedImage.value != null
                            ? DecorationImage(
                                image: FileImage(
                                  controller.selectedImage.value!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: controller.selectedImage.value == null
                          ? const Icon(
                              Icons.add_a_photo,
                              color: Colors.white54,
                              size: 40,
                            )
                          : null,
                    );
                  }),
                ),
              ),

              const SizedBox(height: 35),

              _buildLabel('Full Name'),
              const SizedBox(height: 8),

              TextField(
                controller: controller.nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Enter your name'),
              ),

              const SizedBox(height: 20),

              _buildLabel('Username'),
              const SizedBox(height: 8),

              TextField(
                controller: controller.usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('@username'),
              ),

              const SizedBox(height: 20),

              _buildLabel('Bio'),
              const SizedBox(height: 8),

              TextField(
                controller: controller.bioController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  'Write something about yourself...',
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.continueToFindPeople,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: controller.isSaving.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Obx(
                  () => TextButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.skip,
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white54,
                            ),
                          )
                        : const Text(
                            'Skip for now',
                            style: TextStyle(color: Colors.white60),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF11111A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
