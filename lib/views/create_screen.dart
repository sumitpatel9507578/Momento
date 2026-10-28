import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:momento/routes/app_routes.dart';
import 'package:momento/views/video_filter_preview_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  final _isCameraInitialized = false.obs;
  final _isCameraError = false.obs;
  final _errorMessage = ''.obs;
  CameraLensDirection _currentLens = CameraLensDirection.front;
  final _isFlashOn = false.obs;

  // Selected mode: 'post' | 'story' | 'reel' | 'live'
  final _selectedMode = 'story'.obs; // STORY default

  final _isRecordingVideo = false.obs;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      if (mounted) {
        _isCameraInitialized.value = false;
        _isCameraError.value = false;
      }

      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted) {
        if (mounted) {
          _isCameraError.value = true;
          _errorMessage.value =
              'Camera permission required. Tap to grant permission.';
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          _isCameraError.value = true;
          _errorMessage.value = 'No camera found on device';
        }
        return;
      }

      final selectedCamera = _cameras.firstWhere(
        (c) => c.lensDirection == _currentLens,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: micStatus.isGranted,
      );

      await _cameraController!.initialize();

      if (mounted) {
        _isCameraInitialized.value = true;
      }
    } catch (e) {
      debugPrint('Error initializing camera in CreateScreen: $e');
      if (mounted) {
        _isCameraError.value = true;
        _errorMessage.value = 'Could not access camera. Tap to check permissions.';
      }
    }
  }

  Future<void> _flipCamera() async {
    _currentLens = _currentLens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _cameraController?.dispose();
    _cameraController = null;
    await _initCamera();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized.value) return;
    try {
      _isFlashOn.value = !_isFlashOn.value;
      await _cameraController!.setFlashMode(
        _isFlashOn.value ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> _onShutterTap() async {
    if (_cameraController == null || !_isCameraInitialized.value) return;

    if (_selectedMode.value == 'reel') {
      if (_isRecordingVideo.value) {
        // Stop Video Recording
        try {
          final XFile video = await _cameraController!.stopVideoRecording();
          _isRecordingVideo.value = false;
          _handleCapturedFile(File(video.path), true);
        } catch (e) {
          debugPrint('Error stopping video recording: $e');
        }
      } else {
        // Start Video Recording
        try {
          await _cameraController!.startVideoRecording();
          _isRecordingVideo.value = true;
        } catch (e) {
          debugPrint('Error starting video recording: $e');
        }
      }
    } else if (_selectedMode.value == 'live') {
      Get.snackbar('Notice', 'LIVE coming soon', colorText: Colors.white);
    } else {
      // Photo capture (STORY or POST)
      try {
        final XFile photo = await _cameraController!.takePicture();
        _handleCapturedFile(File(photo.path), false);
      } catch (e) {
        debugPrint('Error taking photo: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? media = await _imagePicker.pickMedia();
      if (media != null) {
        final isVideo =
            media.path.toLowerCase().endsWith('.mp4') ||
            media.path.toLowerCase().endsWith('.mov') ||
            media.path.toLowerCase().endsWith('.avi');
        _handleCapturedFile(File(media.path), isVideo);
      }
    } catch (e) {
      debugPrint('Error picking media from gallery: $e');
      Get.snackbar('Error', 'Could not select media from gallery');
    }
  }

  Future<void> _handleCapturedFile(File file, bool isVideo) async {
    File finalFile = file;

    // For videos, open VideoFilterPreviewScreen first
    if (isVideo) {
      final filteredResult = await Get.to(
        () => VideoFilterPreviewScreen(videoFile: file),
      );
      if (filteredResult is File) {
        finalFile = filteredResult;
      }
    }

    Get.toNamed(
      AppRoutes.upload,
      arguments: {
        'file': finalFile,
        'isVideo': isVideo,
        'mode': _selectedMode.value == 'live' ? 'post' : _selectedMode.value,
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() => Stack(
          fit: StackFit.expand,
          children: [
            // 1. Instagram-Style Rounded Camera Preview Container (with top/bottom spacing)
            Padding(
              padding: const EdgeInsets.only(top: 56, bottom: 140, left: 4, right: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[900],
                  child: _isCameraInitialized.value && _cameraController != null
                      ? AspectRatio(
                          aspectRatio: 1 / _cameraController!.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _cameraController!.value.previewSize?.height ?? 1080,
                                  height: _cameraController!.value.previewSize?.width ?? 1920,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: _isCameraError.value
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _errorMessage.value,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 14),
                                    ElevatedButton(
                                      onPressed: () async {
                                        await openAppSettings();
                                        _initCamera();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                      ),
                                      child: const Text(
                                        'Grant Permissions',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                )
                              : const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                        ),
                ),
              ),
            ),

            // 2. Top Bar Header (X close, Flash, Settings)
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: _toggleFlash,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Get.snackbar(
                      'Notice',
                      'Settings coming soon',
                      colorText: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Left Side Overlay (STORY mode only)
            if (_selectedMode.value == 'story')
              Positioned(
                left: 16,
                top: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftOption(
                      label: 'Create',
                      iconText: 'Aa',
                      onTap: () => Get.snackbar(
                        'Notice',
                        'Create coming soon',
                        colorText: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLeftOption(
                      label: 'Boomerang',
                      iconData: Icons.all_inclusive_rounded,
                      onTap: () => Get.snackbar(
                        'Notice',
                        'Boomerang coming soon',
                        colorText: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLeftOption(
                      label: 'Layout',
                      iconData: Icons.grid_view_rounded,
                      onTap: () => Get.snackbar(
                        'Notice',
                        'Layout coming soon',
                        colorText: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLeftOption(
                      label: 'AR Camera',
                      iconData: Icons.keyboard_arrow_down_rounded,
                      onTap: () => Get.toNamed('/ar-camera'),
                    ),
                  ],
                ),
              ),

            // 4. Bottom Controls (Shutter Button & Gallery / Mode Selector / Flip)
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular Shutter Button
                  GestureDetector(
                    onTap: _onShutterTap,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Obx(() => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isRecordingVideo.value ? 36 : 60,
                          height: _isRecordingVideo.value ? 36 : 60,
                          decoration: BoxDecoration(
                            color: _isRecordingVideo.value
                                ? Colors.redAccent
                                : Colors.white,
                            shape: _isRecordingVideo.value
                                ? BoxShape.rectangle
                                : BoxShape.circle,
                            borderRadius: _isRecordingVideo.value
                                ? BorderRadius.circular(8)
                                : null,
                          ),
                        )),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bottom Bar: Gallery | POST STORY REEL LIVE | Flip Camera
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gallery Pick
                        IconButton(
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _pickFromGallery,
                        ),

                        // Mode Selector (POST | STORY | REEL | LIVE)
                        Row(
                          children: [
                            _buildModeTab('POST', 'post'),
                            const SizedBox(width: 14),
                            _buildModeTab('STORY', 'story'),
                            const SizedBox(width: 14),
                            _buildModeTab('REEL', 'reel'),
                            const SizedBox(width: 14),
                            _buildModeTab('LIVE', 'live'),
                          ],
                        ),

                        // Flip Camera
                        IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _flipCamera,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget _buildLeftOption({
    required String label,
    IconData? iconData,
    String? iconText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconText != null)
            Text(
              iconText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          else if (iconData != null)
            Icon(iconData, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, String mode) {
    return Obx(() {
      final isSelected = _selectedMode.value == mode;
      return GestureDetector(
        onTap: () {
          if (mode == 'live') {
            Get.snackbar('Notice', 'LIVE coming soon', colorText: Colors.white);
            return;
          }
          _selectedMode.value = mode;
        },
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
      );
    });
  }
}
