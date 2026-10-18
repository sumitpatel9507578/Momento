import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../controllers/create_post_controller.dart';
import '../routes/app_routes.dart';

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
                                    ? _VideoPreviewWidget(
                                        file: controller.selectedFile.value!,
                                      )
                                    : Image.file(
                                        controller.selectedFile.value!,
                                        fit: BoxFit.cover,
                                      ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Row(
                                    children: [
                                      // Open in Full Story Editor Panel
                                      CircleAvatar(
                                        backgroundColor: Colors.black67,
                                        child: IconButton(
                                          tooltip: 'Open Editor Panel',
                                          icon: const Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            final file =
                                                controller.selectedFile.value!;
                                            final isVideo = _isVideoFile(file);
                                            Get.toNamed(
                                              AppRoutes.storyEditor,
                                              arguments: {
                                                'mediaPath': file.path,
                                                'mediaType': isVideo
                                                    ? 'video'
                                                    : 'image',
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: Colors.black67,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: controller.removeFile,
                                        ),
                                      ),
                                    ],
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
          _buildModeSelector(context),
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeTab(context, 'POST', 0),
            _buildModeTab(context, 'REEL', 3),
            _buildModeTab(context, 'STORY', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(BuildContext context, String label, int type) {
    return Obx(() {
      final isSelected = controller.selectedType.value == type;
      return GestureDetector(
        onTap: () {
          controller.selectedType.value = type;
          controller.removeFile();
          _showPickerOptions(context);
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

class _VideoPreviewWidget extends StatefulWidget {
  final File file;
  const _VideoPreviewWidget({required this.file});

  @override
  State<_VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<_VideoPreviewWidget> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant _VideoPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    await _controller?.dispose();
    _controller = VideoPlayerController.file(widget.file);
    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing preview video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          c.value.isPlaying ? c.pause() : c.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
          if (!c.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
        ],
      ),
    );
  }
}
