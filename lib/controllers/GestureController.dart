import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/gesture_settings.dart';
import '../models/gesture_state.dart';
import '../models/hand_gesture_type.dart';
import '../routes/app_routes.dart';
import '../services/gesture_recognition_service.dart';
import '../services/gesture_settings_service.dart';

class GestureController extends GetxController with WidgetsBindingObserver {
  final GestureRecognitionService _recognitionService =
      GestureRecognitionService();
  final GestureSettingsService _settingsService = GestureSettingsService();

  // Camera & Landmarker
  CameraController? cameraController;
  HandLandmarkerPlugin? handLandmarker;
  StreamSubscription<List<Hand>>? landmarkSubscription;

  // Observables
  final settings = const GestureSettings().obs;
  final gestureState = GestureState.initializing.obs;
  final isPermissionGranted = false.obs;
  final isCameraInitialized = false.obs;
  final isGestureMode = true.obs;
  final isFlashOn = false.obs;
  final currentLens = CameraLensDirection.front.obs;

  // Gesture Recognition Observables
  final hands = <Hand>[].obs;
  final currentGesture = HandGestureType.none.obs;
  final confidenceScore = 0.0.obs;
  final statusMessage = ''.obs;

  // Countdown & Recording Observables
  final countdownRemaining = 0.obs;
  final recordingDurationSeconds = 0.obs;

  // Internal flags and timers
  bool _isProcessingFrame = false;
  HandGestureType _pendingGesture = HandGestureType.none;
  DateTime? _gestureStartTime;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  Timer? _cooldownTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadSettingsAndInitialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      pauseGestureEngine();
    } else if (state == AppLifecycleState.resumed) {
      resumeGestureEngine();
    }
  }

  Future<void> loadSettingsAndInitialize() async {
    final loadedSettings = await _settingsService.loadSettings();
    settings.value = loadedSettings;
    isGestureMode.value = loadedSettings.isGestureModeEnabled;
    currentLens.value = loadedSettings.cameraLens;
    await startCameraAndEngine();
  }

  Future<void> updateSettings(GestureSettings newSettings) async {
    settings.value = newSettings;
    isGestureMode.value = newSettings.isGestureModeEnabled;
    await _settingsService.saveSettings(newSettings);

    if (currentLens.value != newSettings.cameraLens) {
      currentLens.value = newSettings.cameraLens;
      await restartCamera();
    }
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (status.isGranted && micStatus.isGranted) {
      isPermissionGranted.value = true;
      statusMessage.value = 'Permissions granted';
    } else if (status.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      isPermissionGranted.value = false;
      gestureState.value = GestureState.error;
      statusMessage.value = 'Camera/Microphone permission permanently denied';
      await openAppSettings();
    } else {
      isPermissionGranted.value = false;
      gestureState.value = GestureState.error;
      statusMessage.value = 'Camera permission required for gesture control';
    }
  }

  Future<void> startCameraAndEngine() async {
    try {
      gestureState.value = GestureState.initializing;
      statusMessage.value = 'Initializing camera...';

      await requestCameraPermission();
      if (!isPermissionGranted.value) return;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        gestureState.value = GestureState.error;
        statusMessage.value = 'No camera found on device';
        return;
      }

      final CameraDescription selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == currentLens.value,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();

      // Initialize MediaPipe Hand Landmarker
      statusMessage.value = 'Initializing AI Landmarker...';
      handLandmarker = HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: settings.value.confidenceThreshold,
        delegate: HandLandmarkerDelegate.gpu,
      );

      landmarkSubscription = handLandmarker!.landmarkStream.listen(
        _onLandmarksReceived,
        onError: (err) {
          debugPrint('Landmark Stream Error: $err');
        },
      );

      // Start frame processing
      await cameraController!.startImageStream((CameraImage image) {
        if (!isGestureMode.value ||
            handLandmarker == null ||
            _isProcessingFrame) {
          return;
        }

        _isProcessingFrame = true;
        try {
          handLandmarker!.processFrame(
            image,
            cameraController!.description.sensorOrientation,
          );
        } catch (e) {
          debugPrint('Frame processing exception: $e');
        } finally {
          _isProcessingFrame = false;
        }
      });

      isCameraInitialized.value = true;
      gestureState.value = GestureState.ready;
      statusMessage.value = 'AI Gesture Engine Ready';
    } catch (e) {
      debugPrint('Error starting camera/gesture engine: $e');
      gestureState.value = GestureState.error;
      statusMessage.value = 'Failed to start gesture camera: $e';
    }
  }

  void _onLandmarksReceived(List<Hand> detectedHands) {
    hands.assignAll(detectedHands);

    if (detectedHands.isEmpty) {
      currentGesture.value = HandGestureType.none;
      confidenceScore.value = 0.0;
      _resetPendingGesture();

      if (gestureState.value == GestureState.confirming ||
          gestureState.value == GestureState.gestureDetected) {
        gestureState.value = GestureState.ready;
        statusMessage.value = 'Hand moved away. Ready.';
      }
      return;
    }

    final primaryHand = detectedHands.first;
    final result = _recognitionService.processHandLandmarks(primaryHand);

    currentGesture.value = result.gesture;
    confidenceScore.value = result.confidence;

    if (result.gesture == HandGestureType.none ||
        result.confidence < settings.value.confidenceThreshold) {
      _resetPendingGesture();
      return;
    }

    _handleGestureRecognition(result.gesture, result.confidence);
  }

  void _handleGestureRecognition(HandGestureType gesture, double confidence) {
    if (gestureState.value == GestureState.disabled ||
        gestureState.value == GestureState.capturingPhoto ||
        gestureState.value == GestureState.stoppingRecording ||
        gestureState.value == GestureState.cooldown) {
      return;
    }

    final cfg = settings.value;

    // Check if gesture changed
    if (gesture != _pendingGesture) {
      _pendingGesture = gesture;
      _gestureStartTime = DateTime.now();
      if (gestureState.value != GestureState.recordingVideo) {
        gestureState.value = GestureState.confirming;
        statusMessage.value =
            'Detected ${gesture.displayName}. Hold to confirm...';
      }
      return;
    }

    // Check confirmation hysteresis delay
    final heldDurationMs = DateTime.now()
        .difference(_gestureStartTime ?? DateTime.now())
        .inMilliseconds;

    if (heldDurationMs < cfg.confirmationMs) {
      return; // Still waiting for steady confirmation
    }

    // Gesture confirmed! Execute action
    _executeGestureAction(gesture, cfg);
  }

  void _executeGestureAction(HandGestureType gesture, GestureSettings cfg) {
    // 1. Photo Capture Gesture (e.g. Victory Sign)
    if (cfg.enablePhotoCapture &&
        gesture == cfg.photoGesture &&
        gestureState.value != GestureState.recordingVideo &&
        gestureState.value != GestureState.capturingPhoto) {
      _startPhotoCountdown();
      return;
    }

    // 2. Video Start Gesture (e.g. Thumbs Up)
    if (cfg.enableVideoStart &&
        gesture == cfg.startVideoGesture &&
        gestureState.value != GestureState.recordingVideo &&
        gestureState.value != GestureState.capturingPhoto) {
      startVideoRecording();
      return;
    }

    // 3. Video Stop Gesture (e.g. Closed Fist)
    if (cfg.enableVideoStop &&
        gesture == cfg.stopVideoGesture &&
        gestureState.value == GestureState.recordingVideo) {
      stopVideoRecording();
      return;
    }

    // 4. Camera Switch Gesture (e.g. Swipe Left/Right)
    if (cfg.enableModeSwitch &&
        (gesture == cfg.switchModeGesture ||
            gesture == HandGestureType.swipeLeft ||
            gesture == HandGestureType.swipeRight)) {
      flipCamera();
      _enterCooldown(Duration(seconds: cfg.cooldownSeconds));
      return;
    }
  }

  void _startPhotoCountdown() {
    if (_countdownTimer != null && _countdownTimer!.isActive) return;

    final seconds = settings.value.countdownSeconds;
    if (seconds <= 0) {
      capturePhoto();
      return;
    }

    gestureState.value = GestureState.confirming;
    countdownRemaining.value = seconds;
    _playBeepSound();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdownRemaining.value--;
      if (countdownRemaining.value > 0) {
        _playBeepSound();
      } else {
        timer.cancel();
        capturePhoto();
      }
    });
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    countdownRemaining.value = 0;
    if (gestureState.value != GestureState.recordingVideo) {
      gestureState.value = GestureState.ready;
      statusMessage.value = 'Countdown cancelled';
    }
  }

  Future<void> capturePhoto() async {
    if (cameraController == null ||
        !cameraController!.value.isInitialized ||
        gestureState.value == GestureState.capturingPhoto) {
      return;
    }

    try {
      gestureState.value = GestureState.capturingPhoto;
      statusMessage.value = 'Capturing photo...';
      _playShutterSound();

      final XFile photo = await cameraController!.takePicture();
      statusMessage.value = 'Photo captured!';

      _enterCooldown(Duration(seconds: settings.value.cooldownSeconds));

      // Navigate to media preview screen
      Get.toNamed(
        AppRoutes.arMediaPreview,
        arguments: {'path': photo.path, 'isVideo': false},
      );
    } catch (e) {
      debugPrint('Error taking photo: $e');
      statusMessage.value = 'Failed to capture photo';
      gestureState.value = GestureState.ready;
    }
  }

  Future<void> startVideoRecording() async {
    if (cameraController == null ||
        !cameraController!.value.isInitialized ||
        cameraController!.value.isRecordingVideo ||
        gestureState.value == GestureState.recordingVideo) {
      return;
    }

    try {
      _resetPendingGesture();
      cancelCountdown();

      await cameraController!.startVideoRecording();
      gestureState.value = GestureState.recordingVideo;
      statusMessage.value = 'Recording video...';
      recordingDurationSeconds.value = 0;
      _playBeepSound();

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        recordingDurationSeconds.value++;
      });
    } catch (e) {
      debugPrint('Error starting video recording: $e');
      statusMessage.value = 'Failed to start recording';
      gestureState.value = GestureState.ready;
    }
  }

  Future<void> stopVideoRecording() async {
    if (cameraController == null ||
        !cameraController!.value.isRecordingVideo ||
        gestureState.value == GestureState.stoppingRecording) {
      return;
    }

    try {
      gestureState.value = GestureState.stoppingRecording;
      _recordingTimer?.cancel();
      _playBeepSound();

      final XFile video = await cameraController!.stopVideoRecording();
      statusMessage.value = 'Video recorded successfully!';

      _enterCooldown(Duration(seconds: settings.value.cooldownSeconds));

      Get.toNamed(
        AppRoutes.arMediaPreview,
        arguments: {'path': video.path, 'isVideo': true},
      );
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      statusMessage.value = 'Failed to save video';
      gestureState.value = GestureState.ready;
    }
  }

  void toggleGestureMode() {
    isGestureMode.value = !isGestureMode.value;
    updateSettings(
      settings.value.copyWith(isGestureModeEnabled: isGestureMode.value),
    );
    if (isGestureMode.value) {
      gestureState.value = GestureState.ready;
      statusMessage.value = 'Gesture control enabled';
    } else {
      gestureState.value = GestureState.disabled;
      statusMessage.value = 'Gesture control disabled';
      cancelCountdown();
      hands.clear();
    }
  }

  Future<void> flipCamera() async {
    currentLens.value = currentLens.value == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    updateSettings(settings.value.copyWith(cameraLens: currentLens.value));
    await restartCamera();
  }

  Future<void> toggleFlash() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    try {
      isFlashOn.value = !isFlashOn.value;
      await cameraController!.setFlashMode(
        isFlashOn.value ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> restartCamera() async {
    await stopGestureMode();
    await startCameraAndEngine();
  }

  void _enterCooldown(Duration duration) {
    gestureState.value = GestureState.cooldown;
    _resetPendingGesture();

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(duration, () {
      if (gestureState.value != GestureState.recordingVideo) {
        gestureState.value = GestureState.ready;
        statusMessage.value = 'Ready for gesture';
      }
    });
  }

  void _resetPendingGesture() {
    _pendingGesture = HandGestureType.none;
    _gestureStartTime = null;
  }

  Future<void> pauseGestureEngine() async {
    try {
      cancelCountdown();
      _recordingTimer?.cancel();
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }
    } catch (e) {
      debugPrint('Pause stream error: $e');
    }
  }

  Future<void> resumeGestureEngine() async {
    if (isCameraInitialized.value && cameraController != null) {
      await restartCamera();
    }
  }

  Future<void> stopGestureMode() async {
    cancelCountdown();
    _recordingTimer?.cancel();
    _cooldownTimer?.cancel();

    try {
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }
    } catch (e) {
      debugPrint('Stop stream error: $e');
    }

    await landmarkSubscription?.cancel();
    landmarkSubscription = null;

    handLandmarker?.dispose();
    handLandmarker = null;

    await cameraController?.dispose();
    cameraController = null;

    hands.clear();
    isCameraInitialized.value = false;
  }

  void _playBeepSound() {
    if (!settings.value.enableSoundFeedback) return;
    try {
      _audioPlayer.play(AssetSource('sounds/beep.mp3')).catchError((_) {});
    } catch (_) {}
  }

  void _playShutterSound() {
    if (!settings.value.enableSoundFeedback) return;
    try {
      _audioPlayer.play(AssetSource('sounds/shutter.mp3')).catchError((_) {});
    } catch (_) {}
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    stopGestureMode();
    _audioPlayer.dispose();
    super.onClose();
  }
}
