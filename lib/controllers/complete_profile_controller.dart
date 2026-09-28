import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../repositories/user_repository.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';

class CompleteProfileController extends GetxController {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final bioController = TextEditingController();

  final selectedImage = Rxn<File>();
  final isSaving = false.obs;

  final ImagePicker _picker = ImagePicker();
  final UserRepository _userRepository = UserRepository();
  final ApiService _apiService = Get.find<ApiService>();

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _apiService.getUser();
      if (user != null) {
        if ((user['name'] ?? user['full_name'] ?? '').toString().isNotEmpty) {
          nameController.text = (user['name'] ?? user['full_name']).toString();
        }
        if ((user['username'] ?? '').toString().isNotEmpty) {
          usernameController.text = user['username'].toString();
        }
        if ((user['bio'] ?? '').toString().isNotEmpty) {
          bioController.text = user['bio'].toString();
        }
      }
    } catch (e) {
      debugPrint("Error loading user data in CompleteProfileController: $e");
    }
  }

  Future<void> pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Unable to select image.');
    }
  }

  Future<void> continueToFindPeople() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final bio = bioController.text.trim();

    if (name.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter your name',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (username.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter a username',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (username.contains(' ')) {
      Get.snackbar(
        'Invalid username',
        'Username cannot contain spaces',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSaving.value = true;

      final data = {
        'name': name,
        'full_name': name,
        'username': username,
        'bio': bio.isEmpty ? ' ' : bio,
      };

      final success = await _userRepository.updateProfile(
        data,
        selectedImage.value?.path,
      );

      if (success) {
        Get.offAllNamed(AppRoutes.findPeople);
      } else {
        Get.snackbar(
          'Error',
          'Failed to update profile. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> skip() async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      final userData = await _apiService.getUser();
      final existingName =
          (userData?['name'] ??
                  userData?['full_name'] ??
                  nameController.text.trim())
              .toString();
      final existingUsername =
          (userData?['username'] ?? usernameController.text.trim()).toString();

      final data = <String, String>{
        'bio': ' ', // Dummy space to bypass empty bio check in Splash/Login
      };

      if (existingName.isNotEmpty) {
        data['name'] = existingName;
        data['full_name'] = existingName;
      }
      if (existingUsername.isNotEmpty) {
        data['username'] = existingUsername;
      }

      await _userRepository.updateProfile(data, null);

      if (userData != null) {
        userData['bio'] = ' ';
        await _apiService.saveUser(userData);
      }
    } catch (e) {
      debugPrint("Error in skip profile: $e");
    } finally {
      isSaving.value = false;
      Get.offAllNamed(AppRoutes.findPeople);
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
