import 'dart:async';

import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';

class GestureController extends GetxController {
  CameraController? cameraController;
  HandLandmarkerPlugin? handLandmarker;

  final isPermissionGranted = false.obs;
  final isCameraInitialized = false.obs;
  final isGestureMode = false.obs;
  final hands = <Hand>[].obs;
  final detectedGesture = 'No gesture'.obs;

  DateTime? _lastGestureTime;

  StreamSubscription<List<Hand>>? landmarkSubscription;

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      isPermissionGranted.value = true;
      print('Camera permission granted');
      return;
    }

    isPermissionGranted.value = false;

    if (status.isPermanentlyDenied) {
      print('Camera permission permanently denied');
      await openAppSettings();
    } else {
      print('Camera permission denied');
    }
  }

  Future<void> startGestureMode() async {
    if (isGestureMode.value) return;

    await requestCameraPermission();

    if (!isPermissionGranted.value) {
      return;
    }

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        print('No camera found');
        return;
      }

      final CameraDescription camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();

      handLandmarker = HandLandmarkerPlugin.create(
        numHands: 2,
        minHandDetectionConfidence: 0.7,
        delegate: HandLandmarkerDelegate.gpu,
      );
      landmarkSubscription = handLandmarker!.landmarkStream.listen(
        (result) {
          hands.assignAll(result);

          if (result.isEmpty) {
            detectedGesture.value = 'No hand';
            return;
          }

          final gesture = detectGesture(result.first);
          detectedGesture.value = gesture;

          print('Detected Gesture: $gesture');
        },
        onError: (error) {
          print('Landmark error: $error');
        },
      );

      await cameraController!.startImageStream((CameraImage image) {
        if (handLandmarker == null) return;

        try {
          handLandmarker!.processFrame(
            image,
            cameraController!.description.sensorOrientation,
          );
        } catch (e) {
          print('Frame processing error: $e');
        }
      });

      isCameraInitialized.value = true;
      isGestureMode.value = true;

      print('Gesture mode started');
    } catch (e) {
      print('Gesture mode error: $e');
      await stopGestureMode();
    }
  }

  Future<void> stopGestureMode() async {
    try {
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }
    } catch (e) {
      print('Stop stream error: $e');
    }

    await landmarkSubscription?.cancel();
    landmarkSubscription = null;

    handLandmarker?.dispose();
    handLandmarker = null;

    await cameraController?.dispose();
    cameraController = null;

    hands.clear();

    isCameraInitialized.value = false;
    isGestureMode.value = false;

    print('Gesture mode stopped');
  }

  @override
  void onClose() {
    stopGestureMode();
    super.onClose();
  }

  String detectGesture(Hand hand) {
    if (hand.landmarks.length < 21) {
      return 'Unknown';
    }

    final wrist = hand.landmarks[0];

    final indexMcp = hand.landmarks[5];
    final indexPip = hand.landmarks[6];
    final indexTip = hand.landmarks[8];

    final middleTip = hand.landmarks[12];
    final ringTip = hand.landmarks[16];
    final pinkyTip = hand.landmarks[20];

    // Check whether index finger is extended.
    final bool indexExtended =
        indexTip.y < indexPip.y && indexPip.y < indexMcp.y;

    // Other fingers should be mostly curled.
    final bool otherFingersCurled =
        middleTip.y > indexMcp.y &&
        ringTip.y > indexMcp.y &&
        pinkyTip.y > indexMcp.y;

    if (indexExtended && otherFingersCurled) {
      final double difference = indexTip.x - wrist.x;

      if (difference > 0.15) {
        _markGesture();
        return '👉 Right';
      }

      if (difference < -0.15) {
        _markGesture();
        return '👈 Left';
      }
    }

    return 'Unknown';
  }

  void _markGesture() {
    final now = DateTime.now();

    if (_lastGestureTime == null ||
        now.difference(_lastGestureTime!) > const Duration(milliseconds: 700)) {
      _lastGestureTime = now;
    }
  }
}
