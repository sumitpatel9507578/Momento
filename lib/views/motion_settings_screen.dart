import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/GestureController.dart';

import '../models/hand_gesture_type.dart';
import '../utils/app_colors.dart';

class MotionSettingsScreen extends StatelessWidget {
  const MotionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GestureController controller = Get.put(GestureController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'AI Motion & Gesture Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        final cfg = controller.settings.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Master Switch
              _buildCard(
                child: SwitchListTile(
                  value: cfg.isGestureModeEnabled,
                  onChanged: (val) {
                    controller.updateSettings(
                      cfg.copyWith(isGestureModeEnabled: val),
                    );
                  },
                  title: const Text(
                    'Enable AI Hand Gesture Controls',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    'Control camera photo capture and video recording using on-device computer vision hand gestures.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                  activeThumbColor: AppColors.purple,
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('GESTURE ACTION MAPPINGS'),

              // 1. Photo Capture Mapping
              _buildCard(
                child: Column(
                  children: [
                    _buildGestureDropdownTile(
                      title: 'Photo Capture Gesture',
                      subtitle: 'Gesture used to trigger photo capture',
                      currentValue: cfg.photoGesture,
                      onChanged: (gesture) {
                        if (gesture != null) {
                          controller.updateSettings(
                            cfg.copyWith(photoGesture: gesture),
                          );
                        }
                      },
                    ),
                    const Divider(color: Colors.white10),
                    _buildGestureDropdownTile(
                      title: 'Start Video Recording',
                      subtitle: 'Gesture used to start recording video',
                      currentValue: cfg.startVideoGesture,
                      onChanged: (gesture) {
                        if (gesture != null) {
                          controller.updateSettings(
                            cfg.copyWith(startVideoGesture: gesture),
                          );
                        }
                      },
                    ),
                    const Divider(color: Colors.white10),
                    _buildGestureDropdownTile(
                      title: 'Stop Video Recording',
                      subtitle: 'Gesture used to stop recording video',
                      currentValue: cfg.stopVideoGesture,
                      onChanged: (gesture) {
                        if (gesture != null) {
                          controller.updateSettings(
                            cfg.copyWith(stopVideoGesture: gesture),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('TIMING & CONFIDENCE THRESHOLDS'),

              _buildCard(
                child: Column(
                  children: [
                    // Countdown Duration
                    ListTile(
                      title: Text(
                        'Photo Countdown: ${cfg.countdownSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Slider(
                        value: cfg.countdownSeconds.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '${cfg.countdownSeconds}s',
                        activeColor: AppColors.purple,
                        onChanged: (val) {
                          controller.updateSettings(
                            cfg.copyWith(countdownSeconds: val.toInt()),
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white10),

                    // Hold Confirmation Delay
                    ListTile(
                      title: Text(
                        'Gesture Confirmation Delay: ${cfg.confirmationMs}ms',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Slider(
                        value: cfg.confirmationMs.toDouble(),
                        min: 300,
                        max: 1500,
                        divisions: 12,
                        label: '${cfg.confirmationMs}ms',
                        activeColor: AppColors.purple,
                        onChanged: (val) {
                          controller.updateSettings(
                            cfg.copyWith(confirmationMs: val.toInt()),
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white10),

                    // Confidence Threshold
                    ListTile(
                      title: Text(
                        'Recognition Confidence: ${(cfg.confidenceThreshold * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Slider(
                        value: cfg.confidenceThreshold,
                        min: 0.50,
                        max: 0.90,
                        divisions: 8,
                        label: '${(cfg.confidenceThreshold * 100).toInt()}%',
                        activeColor: AppColors.purple,
                        onChanged: (val) {
                          controller.updateSettings(
                            cfg.copyWith(confidenceThreshold: val),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('VISUAL & AUDIO FEEDBACK'),

              _buildCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: cfg.showLandmarks,
                      onChanged: (val) {
                        controller.updateSettings(
                          cfg.copyWith(showLandmarks: val),
                        );
                      },
                      title: const Text(
                        'Show Hand Skeleton Landmarks',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Display real-time joint skeleton lines over detected hands',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      activeThumbColor: AppColors.purple,
                    ),
                    const Divider(color: Colors.white10),
                    SwitchListTile(
                      value: cfg.enableSoundFeedback,
                      onChanged: (val) {
                        controller.updateSettings(
                          cfg.copyWith(enableSoundFeedback: val),
                        );
                      },
                      title: const Text(
                        'Sound Feedback',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Play audio beep on countdown and shutter capture',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      activeThumbColor: AppColors.purple,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Practice & Open Camera Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed('/gesture');
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'Open AI Gesture Camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: child,
    );
  }

  Widget _buildGestureDropdownTile({
    required String title,
    required String subtitle,
    required HandGestureType currentValue,
    required ValueChanged<HandGestureType?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      trailing: DropdownButton<HandGestureType>(
        value: currentValue,
        dropdownColor: AppColors.surface,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(
            value: HandGestureType.victorySign,
            child: Text('✌️ Victory Sign'),
          ),
          DropdownMenuItem(
            value: HandGestureType.openPalm,
            child: Text('✋ Open Palm'),
          ),
          DropdownMenuItem(
            value: HandGestureType.thumbsUp,
            child: Text('👍 Thumbs Up'),
          ),
          DropdownMenuItem(
            value: HandGestureType.closedFist,
            child: Text('✊ Closed Fist'),
          ),
          DropdownMenuItem(
            value: HandGestureType.pointingUp,
            child: Text('☝️ Pointing Up'),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
