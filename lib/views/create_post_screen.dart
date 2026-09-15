import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/create_post_controller.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class CreatePostScreen extends GetView<CreatePostController> {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Create',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(
            () => controller.isLoading.value
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: controller.selectedFile.value == null
                        ? null
                        : () => controller.uploadContent(),
                    child: Text(
                      'Share',
                      style: TextStyle(
                        color: controller.selectedFile.value == null
                            ? Colors.white24
                            : AppColors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Type Selector
            Padding(
              padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTypeItem(0, 'Photo'),
                  _buildTypeItem(1, 'Video'),
                  _buildTypeItem(2, 'Story'),
                  _buildTypeItem(3, 'Reel'),
                ],
              ),
            ),

            // Preview Area
            GestureDetector(
              onTap: () => _showPickerOptions(context),
              child: Obx(
                () => Container(
                  width: width,
                  height: width,
                  margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    image: controller.selectedFile.value != null
                        ? DecorationImage(
                            image: FileImage(controller.selectedFile.value!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: controller.selectedFile.value == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to add media',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: GestureDetector(
                              onTap: controller.removeFile,
                              child: GlassContainer(
                                padding: const EdgeInsets.all(8),
                                borderRadius: BorderRadius.circular(12),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),

            SizedBox(height: size.height * 0.03),

            // Caption & Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: Column(
                children: [
                  TextField(
                    controller: controller.captionController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a caption...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.02),

                  _buildDetailItem(Icons.location_on_outlined, 'Add Location'),
                  _buildDetailItem(
                    Icons.person_add_alt_1_outlined,
                    'Tag People',
                  ),
                  Obx(
                    () => _buildDetailItem(
                      Icons.music_note_outlined,
                      controller.selectedSong.value?.title ?? 'Add Music',
                      onTap: () async {
                        final song = await Get.toNamed('/music');
                        if (song != null) {
                          controller.selectedSong.value = song;
                        }
                      },
                      trailing: controller.selectedSong.value != null
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white24,
                                size: 16,
                              ),
                              onPressed: () =>
                                  controller.selectedSong.value = null,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.05),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions(BuildContext context) {
    Get.bottomSheet(
      GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Media Source',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Get.back();
                      if (controller.selectedType.value == 1 ||
                          controller.selectedType.value == 3) {
                        controller.pickVideo(ImageSource.camera);
                      } else {
                        controller.pickImage(ImageSource.camera);
                      }
                    },
                  ),
                  _buildPickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Get.back();
                      if (controller.selectedType.value == 1 ||
                          controller.selectedType.value == 3) {
                        controller.pickVideo(ImageSource.gallery);
                      } else {
                        controller.pickImage(ImageSource.gallery);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.purple, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeItem(int index, String label) {
    return Obx(() {
      final isSelected = controller.selectedType.value == index;
      return GestureDetector(
        onTap: () => controller.selectedType.value = index,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildDetailItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white24,
                  size: 14,
                ),
          ],
        ),
      ),
    );
  }
}
