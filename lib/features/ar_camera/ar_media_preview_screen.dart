import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../utils/app_colors.dart';

class ArMediaPreviewScreen extends StatefulWidget {
  const ArMediaPreviewScreen({super.key});

  @override
  State<ArMediaPreviewScreen> createState() => _ArMediaPreviewScreenState();
}

class _ArMediaPreviewScreenState extends State<ArMediaPreviewScreen> {
  late final String mediaPath;
  late final bool isVideo;

  VideoPlayerController? _videoController;
  final RxBool isSaving = false.obs;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    mediaPath = args['path']?.toString() ?? '';
    isVideo = args['isVideo'] == true;

    if (isVideo && mediaPath.isNotEmpty) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.file(File(mediaPath));
    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();
      setState(() {});
    } catch (e) {
      debugPrint('Error playing preview video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _saveToGallery() async {
    if (isSaving.value || mediaPath.isEmpty) return;
    try {
      isSaving.value = true;
      if (isVideo) {
        await Gal.putVideo(mediaPath);
      } else {
        await Gal.putImage(mediaPath);
      }
      Get.snackbar(
        'Saved',
        'Media saved to your gallery!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      Get.snackbar(
        'Error',
        'Could not save to gallery',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _shareMedia() async {
    if (mediaPath.isEmpty) return;
    try {
      await Share.shareXFiles([
        XFile(mediaPath),
      ], text: 'Created with Momento Snapchat AR Filters!');
    } catch (e) {
      debugPrint('Error sharing media: $e');
      Get.snackbar('Error', 'Could not share media');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Preview Content (Image or Video)
            if (isVideo)
              _videoController != null &&
                      _videoController!.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: AppColors.purple),
                    )
            else
              Image.file(File(mediaPath), fit: BoxFit.cover),

            // Top Close / Retake Button
            Positioned(
              top: 16,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
            ),

            // Bottom Action Bar (Save to Gallery, Share, Retake)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Save to Gallery
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed: isSaving.value ? null : _saveToGallery,
                        icon: isSaving.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                              ),
                        label: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[850],
                        ),
                      ),
                    ),

                    // Share Button
                    ElevatedButton.icon(
                      onPressed: _shareMedia,
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Share',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
