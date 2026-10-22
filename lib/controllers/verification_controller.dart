import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:momento/models/verification_application_model.dart';

import '../models/user_model.dart';
import '../models/verification_eligibility_model.dart';
import '../services/verification_service.dart';
import 'profile_controller.dart';

class VerificationController extends GetxController {
  VerificationService get _service => Get.find<VerificationService>();

  final eligibility = Rxn<VerificationEligibilityModel>();
  final currentApplication = Rxn<VerificationApplicationModel>();
  final isLoading = false.obs;

  // Form Fields
  final legalNameController = TextEditingController();
  final displayNameController = TextEditingController();
  final selectedCategory = 'Creator'.obs;
  final countryController = TextEditingController();
  final reasonController = TextEditingController();
  final websiteUrlController = TextEditingController();
  final selectedDocumentType = 'Govt ID'.obs;
  final selectedDocumentFile = Rx<File?>(null);

  final List<String> categories = [
    'Creator',
    'Public Figure',
    'Business',
    'Other',
  ];

  final List<String> documentTypes = [
    'Govt ID',
    'Passport',
    'Driver License',
    'Business Registration',
  ];

  @override
  void onInit() {
    super.onInit();
    loadEligibilityAndStatus();
  }

  Future<void> loadEligibilityAndStatus() async {
    try {
      isLoading.value = true;
      UserModel? me;
      if (Get.isRegistered<ProfileController>(tag: 'me')) {
        me = Get.find<ProfileController>(tag: 'me').currentUser.value;
      }

      if (me != null) {
        legalNameController.text = me.name;
        displayNameController.text = me.name;
        eligibility.value = await _service.checkEligibility(me);
      }

      currentApplication.value = await _service.fetchMyApplicationStatus();
    } catch (e) {
      debugPrint("VerificationController load error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickDocument(ImageSource source) async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        selectedDocumentFile.value = File(file.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to select document file');
    }
  }

  void removeDocument() {
    selectedDocumentFile.value = null;
  }

  Future<void> submitApplication() async {
    if (legalNameController.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Legal name is required.');
      return;
    }
    if (displayNameController.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Public display name is required.');
      return;
    }
    if (reasonController.text.trim().length < 10) {
      Get.snackbar(
        'Validation Error',
        'Please provide a clear reason for verification (at least 10 characters).',
      );
      return;
    }
    if (selectedDocumentFile.value == null) {
      Get.snackbar(
        'Validation Error',
        'Verification identity document is required.',
      );
      return;
    }

    try {
      isLoading.value = true;
      final success = await _service.submitApplication(
        legalName: legalNameController.text.trim(),
        displayName: displayNameController.text.trim(),
        category: selectedCategory.value,
        country: countryController.text.trim(),
        reason: reasonController.text.trim(),
        websiteUrl: websiteUrlController.text.trim(),
        documentType: selectedDocumentType.value,
        documentFilePath: selectedDocumentFile.value!.path,
      );

      if (success) {
        await loadEligibilityAndStatus();
        Get.offNamed('/verification-status');
        Get.snackbar(
          'Application Submitted',
          'Your verification request has been submitted for review.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Error', 'Failed to submit application. Try again.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resubmitApplication(String appId, String notes) async {
    try {
      isLoading.value = true;
      final success = await _service.resubmitApplication(
        appId: appId,
        updatedNotes: notes,
        newDocumentFilePath: selectedDocumentFile.value?.path,
      );

      if (success) {
        await loadEligibilityAndStatus();
        Get.back();
        Get.snackbar(
          'Resubmitted',
          'Your updated information has been submitted.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to resubmit: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    legalNameController.dispose();
    displayNameController.dispose();
    countryController.dispose();
    reasonController.dispose();
    websiteUrlController.dispose();
    super.onClose();
  }
}
