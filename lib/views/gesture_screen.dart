import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/GestureController.dart';

class GestureScreen extends StatelessWidget {
  GestureScreen({super.key});

  final GestureController controller = Get.put(GestureController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08080D),
        foregroundColor: Colors.white,
        title: const Text('Hand Gesture Navigation'),
      ),
      body: Obx(() {
        if (!controller.isGestureMode.value) {
          return Center(
            child: ElevatedButton.icon(
              onPressed: controller.startGestureMode,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Enable Hand Gestures'),
            ),
          );
        }

        if (!controller.isCameraInitialized.value ||
            controller.cameraController == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.cameraController!.value.aspectRatio,
                child: CameraPreview(controller.cameraController!),
              ),
            ),

            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.hands.isEmpty
                          ? 'Hand not detected'
                          : 'Hand detected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hands: ${controller.hands.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 30,
              left: 30,
              right: 30,
              child: ElevatedButton(
                onPressed: controller.stopGestureMode,
                child: const Text('Stop Gesture Mode'),
              ),
            ),
          ],
        );
      }),
    );
  }
}
