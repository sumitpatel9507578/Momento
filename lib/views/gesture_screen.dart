import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/GestureController.dart';
import '../models/gesture_settings.dart';
import '../models/gesture_state.dart';
import '../models/hand_gesture_type.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import 'widgets/hand_landmark_painter.dart';

class GestureScreen extends StatelessWidget {
  const GestureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GestureController controller = Get.put(GestureController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          if (!controller.isPermissionGranted.value &&
              controller.gestureState.value == GestureState.error) {
            return _buildPermissionDeniedUI(context, controller);
          }

          if (!controller.isCameraInitialized.value ||
              controller.cameraController == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.purple),
                  SizedBox(height: 16),
                  Text(
                    'Initializing AI Gesture Engine...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Preview
              Center(
                child: AspectRatio(
                  aspectRatio: controller.cameraController!.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(controller.cameraController!),

                      // Landmark Overlay
                      if (controller.settings.value.showLandmarks &&
                          controller.hands.isNotEmpty)
                        CustomPaint(
                          painter: HandLandmarkPainter(
                            hands: controller.hands,
                            currentGesture: controller.currentGesture.value,
                            confidence: controller.confidenceScore.value,
                            isFrontCamera:
                                controller.currentLens.value ==
                                CameraLensDirection.front,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Top Action Bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ),

                    // Title / Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: controller.isGestureMode.value
                              ? AppColors.purple
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.isGestureMode.value
                                ? Icons.pan_tool_alt_rounded
                                : Icons.pan_tool_outlined,
                            color: controller.isGestureMode.value
                                ? AppColors.purple
                                : Colors.white54,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.isGestureMode.value
                                ? 'AI Gesture Mode ON'
                                : 'Gesture Mode OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        // Flash
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: Icon(
                              controller.isFlashOn.value
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color: Colors.white,
                            ),
                            onPressed: controller.toggleFlash,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Flip Camera
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(
                              Icons.flip_camera_ios_rounded,
                              color: Colors.white,
                            ),
                            onPressed: controller.flipCamera,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Gesture Settings
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                Get.toNamed(AppRoutes.motionSettings),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Floating Detected Gesture Badge
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 20,
                right: 20,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          controller.currentGesture.value ==
                              HandGestureType.none
                          ? Colors.black45
                          : AppColors.purple.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (controller.currentGesture.value !=
                            HandGestureType.none)
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.currentGesture.value.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.currentGesture.value ==
                                  HandGestureType.none
                              ? (controller.hands.isEmpty
                                    ? 'Show hand in frame'
                                    : 'Analyzing gesture...')
                              : '${controller.currentGesture.value.displayName} (${(controller.confidenceScore.value * 100).toInt()}%)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Video Recording Duration Badge (When Recording)
              if (controller.gestureState.value == GestureState.recordingVideo)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDuration(
                              controller.recordingDurationSeconds.value,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 5. Center Countdown Overlay
              if (controller.countdownRemaining.value > 0)
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black87,
                      border: Border.all(color: AppColors.purple, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${controller.countdownRemaining.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Capturing...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 6. Bottom Controls Bar
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gesture Quick Toggle & Action Hints Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: 'Quick Gesture Toggle',
                            icon: Icon(
                              controller.isGestureMode.value
                                  ? Icons.pan_tool_rounded
                                  : Icons.pan_tool_outlined,
                              color: controller.isGestureMode.value
                                  ? AppColors.purple
                                  : Colors.white54,
                              size: 28,
                            ),
                            onPressed: controller.toggleGestureMode,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              controller.statusMessage.value.isEmpty
                                  ? 'Show ✌️ for Photo | 👍 for Video'
                                  : controller.statusMessage.value,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Gesture Guide',
                            icon: const Icon(
                              Icons.help_outline_rounded,
                              color: Colors.white70,
                              size: 26,
                            ),
                            onPressed: () =>
                                _showGestureHelpSheet(context, controller),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Manual Capture / Video Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Shutter / Record Button
                        GestureDetector(
                          onTap: () async {
                            if (controller.gestureState.value ==
                                GestureState.recordingVideo) {
                              await controller.stopVideoRecording();
                            } else {
                              await controller.capturePhoto();
                            }
                          },
                          onLongPressStart: (_) async {
                            if (controller.gestureState.value !=
                                GestureState.recordingVideo) {
                              await controller.startVideoRecording();
                            }
                          },
                          onLongPressEnd: (_) async {
                            if (controller.gestureState.value ==
                                GestureState.recordingVideo) {
                              await controller.stopVideoRecording();
                            }
                          },
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color:
                                  controller.gestureState.value ==
                                      GestureState.recordingVideo
                                  ? Colors.redAccent
                                  : Colors.white30,
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width:
                                    controller.gestureState.value ==
                                        GestureState.recordingVideo
                                    ? 40
                                    : 62,
                                height:
                                    controller.gestureState.value ==
                                        GestureState.recordingVideo
                                    ? 40
                                    : 62,
                                decoration: BoxDecoration(
                                  shape:
                                      controller.gestureState.value ==
                                          GestureState.recordingVideo
                                      ? BoxShape.rectangle
                                      : BoxShape.circle,
                                  borderRadius:
                                      controller.gestureState.value ==
                                          GestureState.recordingVideo
                                      ? BorderRadius.circular(8)
                                      : null,
                                  color:
                                      controller.gestureState.value ==
                                          GestureState.recordingVideo
                                      ? Colors.red
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPermissionDeniedUI(
    BuildContext context,
    GestureController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Momento AI Gesture Control requires camera access to detect hand gestures in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.startCameraAndEngine,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGestureHelpSheet(
    BuildContext context,
    GestureController controller,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF14141E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          children: [
            const Center(
              child: Text(
                'AI Hand Gesture Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildGestureInfoRow(
              '✌️ Victory Sign',
              'Capture Photo (Countdown)',
            ),
            _buildGestureInfoRow('👍 Thumbs Up', 'Start Video Recording'),
            _buildGestureInfoRow('✊ Closed Fist', 'Stop Video Recording'),
            _buildGestureInfoRow('👈 / 👉 Swipe', 'Switch Camera / Filter'),
            _buildGestureInfoRow('✋ Open Palm', 'Gesture Mode Detection'),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.motionSettings);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                ),
                child: const Text(
                  'Customize Gestures in Settings',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureInfoRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
