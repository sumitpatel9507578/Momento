import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/story_editor_controller.dart';
import '../../../utils/app_colors.dart';

class MoreOptionsSheet extends GetView<StoryEditorController> {
  const MoreOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.5,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Story Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                Obx(
                  () => SwitchListTile(
                    title: const Text('Allow Replies', style: TextStyle(color: Colors.white)),
                    value: controller.allowReplies.value,
                    activeColor: AppColors.purple,
                    onChanged: (val) => controller.allowReplies.value = val,
                  ),
                ),
                Obx(
                  () => SwitchListTile(
                    title: const Text('Allow Sharing', style: TextStyle(color: Colors.white)),
                    value: controller.allowSharing.value,
                    activeColor: AppColors.purple,
                    onChanged: (val) => controller.allowSharing.value = val,
                  ),
                ),
                const Divider(color: Colors.white24),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Alt Text',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ),
                TextField(
                  onChanged: (val) => controller.altText.value = val,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Write alt text for accessibility...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
