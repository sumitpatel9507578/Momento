import 'dart:async';

import 'package:deepar_flutter/deepar_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ar_config.dart';
import 'ar_filter_model.dart';

class ArCameraController extends GetxController {
  late final DeepArController deepArController;

  final isPermissionGranted = false.obs;
  final isPermissionPermanentlyDenied = false.obs;
  final isInitializing = true.obs;
  final initError = ''.obs;

  final selectedCategory = ArFilterCategory.funny.obs;
  final activeFilterIndex = 0.obs;
  final currentFilters = <ArFilterModel>[].obs;

  final isRecording = false.obs;
  final recordingDurationSeconds = 0.obs;
  Timer? _recordingTimer;

  final isFlashOn = false.obs;

  @override
  void onInit() {
    super.onInit();
    deepArController = DeepArController();
    _updateCategoryFilters(selectedCategory.value);
    checkAndRequestPermissions();
  }

  void _updateCategoryFilters(ArFilterCategory cat) {
    selectedCategory.value = cat;
    currentFilters.assignAll(ArFilterModel.getByCategory(cat));
    activeFilterIndex.value = 0;
  }

  Future<void> checkAndRequestPermissions() async {
    isInitializing.value = true;
    initError.value = '';

    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && micStatus.isGranted) {
      isPermissionGranted.value = true;
      isPermissionPermanentlyDenied.value = false;
      await initDeepAR();
    } else if (cameraStatus.isPermanentlyDenied ||
        micStatus.isPermanentlyDenied) {
      isPermissionGranted.value = false;
      isPermissionPermanentlyDenied.value = true;
      isInitializing.value = false;
    } else {
      isPermissionGranted.value = false;
      isPermissionPermanentlyDenied.value = false;
      isInitializing.value = false;
    }
  }

  Future<void> initDeepAR() async {
    try {
      isInitializing.value = true;
      initError.value = '';

      await deepArController.initialize(
        androidLicenseKey: ArConfig.androidLicenseKey,
        iosLicenseKey: ArConfig.iosLicenseKey,
        resolution: Resolution.high,
      );

      isInitializing.value = false;

      // Apply initial filter if available
      if (currentFilters.isNotEmpty) {
        applyFilter(currentFilters[0]);
      }
    } catch (e) {
      debugPrint('DeepAR init error: $e');
      initError.value =
          'Could not initialize AR Camera. Please check license key or device camera.';
      isInitializing.value = false;
    }
  }

  void selectCategory(ArFilterCategory cat) {
    _updateCategoryFilters(cat);
    if (currentFilters.isNotEmpty) {
      applyFilter(currentFilters[0]);
    }
  }

  void selectFilterIndex(int index) {
    if (index < 0 || index >= currentFilters.length) return;
    activeFilterIndex.value = index;
    applyFilter(currentFilters[index]);
  }

  Future<void> applyFilter(ArFilterModel filter) async {
    try {
      if (deepArController.isInitialized) {
        debugPrint(
          'Applying AR Filter: ${filter.name} (${filter.category.name}) [Type: ${filter.filterType.name}] -> ${filter.assetPath}',
        );

        // Reset/clear active slots first to avoid overlapping or blocked filters
        try {
          await deepArController.switchEffect('null');
          await deepArController.switchFaceMask('null');
          await deepArController.switchFilter('null');
        } catch (_) {}

        switch (filter.filterType) {
          case ArFilterType.mask:
            await deepArController.switchFaceMask(filter.assetPath);
            break;
          case ArFilterType.filter:
            await deepArController.switchFilter(filter.assetPath);
            break;
          case ArFilterType.effect:
            await deepArController.switchEffect(filter.assetPath);
            break;
        }
      } else {
        debugPrint('DeepAR controller not initialized yet for ${filter.name}');
      }
    } catch (e) {
      debugPrint('Error applying filter ${filter.name}: $e');
    }
  }

  Future<void> flipCamera() async {
    try {
      if (deepArController.isInitialized) {
        await deepArController.flipCamera();
      }
    } catch (e) {
      debugPrint('Error flipping camera: $e');
    }
  }

  Future<void> toggleFlash() async {
    try {
      if (deepArController.isInitialized) {
        await deepArController.toggleFlash();
        isFlashOn.toggle();
      }
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<String?> takePhoto() async {
    try {
      if (!deepArController.isInitialized) return null;
      final file = await deepArController.takeScreenshot();
      return file.path;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      Get.snackbar('Error', 'Could not capture photo');
      return null;
    }
  }

  Future<void> startVideoRecording() async {
    try {
      if (!deepArController.isInitialized || isRecording.value) return;
      await deepArController.startVideoRecording();
      isRecording.value = true;
      recordingDurationSeconds.value = 0;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordingDurationSeconds.value++;
      });
    } catch (e) {
      debugPrint('Error starting video recording: $e');
      Get.snackbar('Error', 'Could not start recording video');
    }
  }

  Future<String?> stopVideoRecording() async {
    try {
      if (!isRecording.value) return null;
      _recordingTimer?.cancel();
      isRecording.value = false;
      final file = await deepArController.stopVideoRecording();
      return file.path;
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      _recordingTimer?.cancel();
      isRecording.value = false;
      Get.snackbar('Error', 'Could not save recorded video');
      return null;
    }
  }

  @override
  void onClose() {
    _recordingTimer?.cancel();
    try {
      deepArController.destroy();
    } catch (_) {}
    super.onClose();
  }
}
