import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/song_model.dart';
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
  final Rx<File?> selectedFile = Rx<File?>(null);
  final selectedSong = Rxn<SongModel>();
  final isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );

      if (image != null) {
        selectedFile.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(source: source);

      if (video != null) {
        selectedFile.value = File(video.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick video');
    }
  }

  Future<void> uploadContent() async {
    if (selectedFile.value == null) {
      Get.snackbar('Error', 'Please select a file');
      return;
    }

    try {
      isLoading.value = true;
      bool success = false;

      switch (selectedType.value) {
        case 0: // Photo Post
          success = await _postService.createPost(
            captionController.text,
            selectedFile.value!.path,
            'image',
          );
          break;
        case 1: // Video Post
          success = await _postService.createPost(
            captionController.text,
            selectedFile.value!.path,
            'video',
          );
          break;
        case 2: // Story
          final isVideo =
              selectedFile.value!.path.toLowerCase().endsWith('.mp4') ||
              selectedFile.value!.path.toLowerCase().endsWith('.mov');
          success = await _storyService.createStory(
            selectedFile.value!.path,
            isVideo ? 'video' : 'image',
            caption: captionController.text,
          );
          break;
        case 3: // Reel
          success = await _reelService.createReel(
            captionController.text,
            selectedFile.value!.path,
            songId: selectedSong.value?.id,
          );
          break;
      }

      if (success) {
        // Refresh Feed, Stories, or Reels depending on uploaded type
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
            : (selectedType.value == 3 ? 'Reel' : 'Post');
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

  void removeFile() {
    selectedFile.value = null;
    selectedSong.value = null;
  }

  @override
  void onClose() {
    captionController.dispose();
    super.onClose();
  }
}
