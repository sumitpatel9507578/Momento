import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/create_post_controller.dart';

class CreatePostScreen extends GetView<CreatePostController> {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Obx(() {
          switch (controller.selectedType.value) {
            case 2:
              return const Text(
                'New Story',
                style: TextStyle(fontWeight: FontWeight.bold),
              );
            case 3:
              return const Text(
                'New Reel',
                style: TextStyle(fontWeight: FontWeight.bold),
              );
            default:
              return const Text(
                'New Post',
                style: TextStyle(fontWeight: FontWeight.bold),
              );
          }
        }),
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  controller.selectedFile.value == null ||
                      controller.isLoading.value
                  ? null
                  : () => controller.uploadContent(),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    )
                  : Text(
                      'Share',
                      style: TextStyle(
                        color: controller.selectedFile.value == null
                            ? Colors.white24
                            : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Obx(
                    () => Container(
                      height: 380,
                      width: double.infinity,
                      color: Colors.grey[900],
                      child: controller.selectedFile.value == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_a_photo,
                                      size: 50,
                                      color: Colors.white38,
                                    ),
                                    onPressed: () =>
                                        _showPickerOptions(context),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    controller.selectedType.value == 3
                                        ? 'Tap to select a Reel Video'
                                        : (controller.selectedType.value == 2
                                              ? 'Tap to select a Story Image/Video'
                                              : 'Tap to select a Post Image/Video'),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                _isVideoFile(controller.selectedFile.value!)
                                    ? Container(
                                        color: Colors.black87,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.video_library_rounded,
                                              size: 60,
                                              color: Colors.blueAccent,
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Video Selected',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                  ),
                                              child: Text(
                                                controller
                                                    .selectedFile
                                                    .value!
                                                    .path
                                                    .split('/')
                                                    .last,
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Image.file(
                                        controller.selectedFile.value!,
                                        fit: BoxFit.cover,
                                      ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: controller.removeFile,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: controller.captionController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Write a caption...',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.white),
                    title: Obx(
                      () => Text(
                        controller.selectedSong.value?.title ?? 'Add Music',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                    onTap: () async {
                      final song = await Get.toNamed('/music');
                      if (song != null) controller.selectedSong.value = song;
                    },
                  ),
                  const Divider(color: Colors.white10),
                ],
              ),
            ),
          ),

          // Bottom Mode Selector Bar (POST | REEL | STORY)
          _buildModeSelector(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeTab('POST', 0),
            _buildModeTab('REEL', 3),
            _buildModeTab('STORY', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, int type) {
    return Obx(() {
      final isSelected = controller.selectedType.value == type;
      return GestureDetector(
        onTap: () {
          controller.selectedType.value = type;
          controller.removeFile();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: Colors.white54, width: 1)
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
    });
  }

  void _showPickerOptions(BuildContext context) {
    final isReel = controller.selectedType.value == 3;

    Get.bottomSheet(
      Container(
        color: Colors.grey[900],
        child: Wrap(
          children: [
            if (!isReel)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'Camera (Photo)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Get.back();
                  controller.pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: Text(
                isReel ? 'Gallery (Video)' : 'Gallery (Photo)',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Get.back();
                if (isReel) {
                  controller.pickVideo(ImageSource.gallery);
                } else {
                  controller.pickImage(ImageSource.gallery);
                }
              },
            ),
            if (isReel)
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.white),
                title: const Text(
                  'Record Video (Reel)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Get.back();
                  controller.pickVideo(ImageSource.camera);
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _isVideoFile(File file) {
    final lower = file.path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }
}
