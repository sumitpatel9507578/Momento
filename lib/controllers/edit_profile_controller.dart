import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_controller.dart';

class EditProfileController extends GetxController {
  final ProfileController profileController = Get.find<ProfileController>();

  final ImagePicker _picker = ImagePicker();

  late final TextEditingController nameController;
  late final TextEditingController usernameController;
  late final TextEditingController bioController;

  final Rxn<File> selectedImage = Rxn<File>();
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();

    final user = profileController.currentUser.value;

    nameController = TextEditingController(text: user?.name ?? '');

    usernameController = TextEditingController(text: user?.username ?? '');

    bioController = TextEditingController(text: user?.bio ?? '');
  }

  Future<void> pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) {
        return;
      }

      selectedImage.value = File(image.path);
    } catch (e) {
      Get.snackbar('Error', 'Unable to select image.');
    }
  }

  void removeSelectedImage() {
    selectedImage.value = null;
  }

  Future<void> saveProfile() async {
    final user = profileController.currentUser.value;

    if (user == null) {
      Get.snackbar('Error', 'Profile not found.');
      return;
    }

    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final bio = bioController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Required', 'Name cannot be empty.');
      return;
    }

    if (username.isEmpty) {
      Get.snackbar('Required', 'Username cannot be empty.');
      return;
    }

    try {
      isSaving.value = true;

      String profileImage = user.profileImage;

      // Temporary:
      // RandomUser API ke saath local image preview use kar rahe hain.
      if (selectedImage.value != null) {
        profileImage = selectedImage.value!.path;
      }

      final updatedUser = user.copyWith(
        name: name,
        username: username,
        bio: bio,
        profileImage: profileImage,
      );

      profileController.currentUser.value = updatedUser;

      Get.snackbar('Success', 'Profile updated successfully.');

      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Unable to update profile.');
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    usernameController.dispose();
    bioController.dispose();

    super.onClose();
  }
}
