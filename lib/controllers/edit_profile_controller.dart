import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/user_repository.dart';
import 'profile_controller.dart';

class EditProfileController extends GetxController {
  // Edit profile is always for the current user ('me')
  final ProfileController profileController = Get.find<ProfileController>(
    tag: 'me',
  );
  final UserRepository _userRepository = UserRepository();
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

    ever(profileController.currentUser, (newUser) {
      if (newUser != null) {
        if (nameController.text.isEmpty) nameController.text = newUser.name;
        if (usernameController.text.isEmpty) usernameController.text = newUser.username;
        if (bioController.text.isEmpty) bioController.text = newUser.bio;
      }
    });
  }

  Future<void> pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Unable to select image.');
    }
  }

  void removeSelectedImage() {
    selectedImage.value = null;
  }

  Future<void> saveProfile() async {
    final user = profileController.currentUser.value;
    if (user == null) return;

    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final bio = bioController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      Get.snackbar('Required', 'Name and Username are required.');
      return;
    }

    try {
      isSaving.value = true;

      final Map<String, String> updates = {'full_name': name, 'bio': bio};

      final success = await _userRepository.updateProfile(
        updates,
        selectedImage.value?.path,
      );

      if (success) {
        await profileController.loadProfile(forceRefresh: true); // Refresh main profile state
        Get.back();
        Get.snackbar('Success', 'Profile updated successfully.');
      } else {
        Get.snackbar('Error', 'Failed to update profile on server.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong.');
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
