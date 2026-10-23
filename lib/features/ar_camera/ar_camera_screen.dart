import 'package:deepar_flutter/deepar_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';
import 'ar_camera_controller.dart';
import 'ar_filter_model.dart';

class ArCameraScreen extends StatefulWidget {
  const ArCameraScreen({super.key});

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ArCameraController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          if (!controller.isPermissionGranted.value) {
            return _buildPermissionDeniedUI(context, controller);
          }

          if (controller.isInitializing.value) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.purple),
                  SizedBox(height: 16),
                  Text(
                    'Initializing AR Camera...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (controller.initError.value.isNotEmpty) {
            return _buildErrorUI(context, controller);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. DeepAR Camera Preview - Static, never recreated on filter taps
              DeepArPreview(controller.deepArController),

              // 2. Top Action Bar (Close, Category Tabs, Flash, Flip)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ),

                    // Top Category Selector Tabs (Funny, Romantic, Serious)
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Obx(() {
                            final currentCat =
                                controller.selectedCategory.value;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: ArFilterCategory.values.map((cat) {
                                final isSelected = currentCat == cat;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    debugPrint(
                                      'AR Category Tapped: ${cat.displayName}',
                                    );
                                    controller.selectCategory(cat);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.purple
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      cat.displayName,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: Obx(
                            () => IconButton(
                              icon: Icon(
                                controller.isFlashOn.value
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                color: Colors.white,
                              ),
                              onPressed: controller.toggleFlash,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: IconButton(
                            icon: const Icon(
                              Icons.flip_camera_ios_rounded,
                              color: Colors.white,
                            ),
                            onPressed: controller.flipCamera,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Recording Timer Indicator
              Obx(() {
                if (!controller.isRecording.value) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
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
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // 4. Bottom Controls (Filter Carousel + Capture Button)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filter Horizontal Carousel
                    SizedBox(
                      height: 92,
                      child: Obx(() {
                        final filters = controller.currentFilters;
                        final activeIdx = controller.activeFilterIndex.value;

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filters.length,
                          itemBuilder: (context, index) {
                            final filter = filters[index];
                            final isSelected = activeIdx == index;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                debugPrint(
                                  'AR Filter Tapped: ${filter.name} (index: $index)',
                                );
                                controller.selectFilterIndex(index);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: isSelected ? 56 : 48,
                                      height: isSelected ? 56 : 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.purple
                                              : Colors.white54,
                                          width: isSelected ? 3 : 1.5,
                                        ),
                                        color: Colors.black45,
                                      ),
                                      child: Icon(
                                        filter.iconData,
                                        color: isSelected
                                            ? AppColors.purple
                                            : Colors.white,
                                        size: isSelected ? 26 : 22,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      filter.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.purple
                                            : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // Snapchat Style Capture Button
                    Obx(() {
                      final recording = controller.isRecording.value;
                      return GestureDetector(
                        onTap: () async {
                          final path = await controller.takePhoto();
                          if (path != null && path.isNotEmpty) {
                            Get.toNamed(
                              AppRoutes.arMediaPreview,
                              arguments: {'path': path, 'isVideo': false},
                            );
                          }
                        },
                        onLongPressStart: (_) async {
                          await controller.startVideoRecording();
                        },
                        onLongPressEnd: (_) async {
                          final path = await controller.stopVideoRecording();
                          if (path != null && path.isNotEmpty) {
                            Get.toNamed(
                              AppRoutes.arMediaPreview,
                              arguments: {'path': path, 'isVideo': true},
                            );
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: recording
                                ? Colors.redAccent
                                : Colors.white30,
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: recording ? 40 : 60,
                              height: recording ? 40 : 60,
                              decoration: BoxDecoration(
                                shape: recording
                                    ? BoxShape.rectangle
                                    : BoxShape.circle,
                                borderRadius: recording
                                    ? BorderRadius.circular(8)
                                    : null,
                                color: recording ? Colors.red : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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
    ArCameraController controller,
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
              'To use Snapchat AR Face Filters, Momento needs access to your camera and microphone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (controller.isPermissionPermanentlyDenied.value) {
                  openAppSettings();
                } else {
                  controller.checkAndRequestPermissions();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                controller.isPermissionPermanentlyDenied.value
                    ? 'Open Settings'
                    : 'Grant Permission',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorUI(BuildContext context, ArCameraController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.amberAccent,
            ),
            const SizedBox(height: 16),
            Text(
              controller.initError.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.initDeepAR,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
