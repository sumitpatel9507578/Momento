import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/song_model.dart';
import '../routes/app_routes.dart';
import '../services/post_service.dart';
import '../services/reel_service.dart';
import '../services/story_service.dart';
import 'home_controller.dart';
import 'profile_controller.dart';
import 'reel_controller.dart';
import 'story_controller.dart';

class CreatePostController extends GetxController {
  final PostService _postService = Get.find<PostService>();
  final ReelService _reelService = Get.find<ReelService>();
  final StoryService _storyService = Get.find<StoryService>();

  final captionController = TextEditingController();
  final selectedType = 0.obs;
  final Rxn<File> selectedFile = Rxn<File>();
  final selectedFiles = <File>[].obs;
  final selectedSong = Rxn<SongModel>();
  final isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();

  File? get primaryFile =>
      selectedFile.value ?? (selectedFiles.isNotEmpty ? selectedFiles.first : null);

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        selectedFiles.clear();
        final file = File(image.path);
        selectedFiles.add(file);
        selectedFile.value = file;
        if (selectedType.value == 2) {
          Get.toNamed(
            AppRoutes.storyEditor,
            arguments: {'mediaPath': image.path, 'mediaType': 'image'},
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        selectedFiles.clear();
        for (final img in images.take(10)) {
          selectedFiles.add(File(img.path));
        }
        selectedFile.value = selectedFiles.first;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick multiple images');
    }
  }

  Future<void> addMoreImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        for (final img in images) {
          if (selectedFiles.length < 10) {
            selectedFiles.add(File(img.path));
          }
        }
        if (selectedFile.value == null && selectedFiles.isNotEmpty) {
          selectedFile.value = selectedFiles.first;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add images');
    }
  }

  Future<void> pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(source: source);

      if (video != null) {
        selectedFiles.clear();
        final file = File(video.path);
        selectedFiles.add(file);
        selectedFile.value = file;
        if (selectedType.value == 2) {
          Get.toNamed(
            AppRoutes.storyEditor,
            arguments: {'mediaPath': video.path, 'mediaType': 'video'},
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video');
    }
  }

  void removeFileAt(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
      selectedFile.value =
          selectedFiles.isNotEmpty ? selectedFiles.first : null;
    }
  }

  void removeFile() {
    selectedFiles.clear();
    selectedFile.value = null;
    selectedSong.value = null;
  }

  Future<void> uploadContent() async {
    if (selectedFiles.isEmpty && selectedFile.value != null) {
      selectedFiles.add(selectedFile.value!);
    }

    if (selectedFiles.isEmpty) {
      Get.snackbar('Error', 'Please select at least one photo or video');
      return;
    }

    try {
      isLoading.value = true;
      bool success = false;

      final filePaths = selectedFiles.map((f) => f.path).toList();

      switch (selectedType.value) {
        case 0: // Photo/Carousel Post
          if (filePaths.length > 1) {
            success = await _postService.createCarouselPost(
              captionController.text,
              filePaths,
            );
          } else {
            success = await _postService.createPost(
              captionController.text,
              filePaths.first,
              'image',
            );
          }
          break;
        case 1: // Video Post
          success = await _postService.createPost(
            captionController.text,
            filePaths.first,
            'video',
          );
          break;
        case 2: // Story
          final isVideo =
              filePaths.first.toLowerCase().endsWith('.mp4') ||
              filePaths.first.toLowerCase().endsWith('.mov');
          success = await _storyService.createStory(
            filePaths.first,
            isVideo ? 'video' : 'image',
            caption: captionController.text,
          );
          break;
        case 3: // Reel
          success = await _reelService.createReel(
            captionController.text,
            filePaths.first,
            songId: selectedSong.value?.id,
          );
          break;
      }

      if (success) {
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();
          homeController.changeTab(0);
          homeController.loadPosts();
        }
        if (Get.isRegistered<StoryController>()) {
          Get.find<StoryController>().loadStories();
        }
        if (Get.isRegistered<ReelController>()) {
          Get.find<ReelController>().refreshReels();
        }
        if (Get.isRegistered<ProfileController>(tag: 'me')) {
          Get.find<ProfileController>(
            tag: 'me',
          ).loadProfile(forceRefresh: true);
        }

        final typeName = selectedType.value == 2
            ? 'Story'
            : (selectedType.value == 3
                  ? 'Reel'
                  : (filePaths.length > 1 ? 'Carousel Post' : 'Post'));
        Get.snackbar('Success', '$typeName shared successfully!');
        removeFile();
        captionController.clear();
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      print("Upload Error: $e");
      Get.snackbar('Error', 'Failed to share. Try again.');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    captionController.dispose();
    super.onClose();
  }
}
