import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/song_model.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';

class StoryController extends GetxController {
  final StoryService _service = Get.find<StoryService>();

  final stories = <StoryModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final currentStoryIndex = 0.obs;
  final progress = 0.0.obs;
  bool _isPaused = false;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    loadStories();

    ever(currentStoryIndex, (int index) {
      if (stories.isNotEmpty && index >= 0 && index < stories.length) {
        markAsViewed(stories[index].storyId);
      }
    });
  }

  Future<void> loadStories() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _service.fetchStories();
      stories.assignAll(result);
    } catch (e) {
      errorMessage.value = 'No stories yet.';
    } finally {
      isLoading.value = false;
    }
  }

  void markAsViewed(String storyId) async {
    final index = stories.indexWhere((s) => s.storyId == storyId);
    if (index != -1 && !stories[index].viewed) {
      stories[index] = stories[index].copyWith(viewed: true);
      await _service.markAsViewed(storyId);
    }
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused) {
        if (progress.value < 1.0) {
          progress.value += 0.01;
        } else {
          nextStory();
        }
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void nextStory() {
    if (currentStoryIndex.value < stories.length - 1) {
      currentStoryIndex.value++;
      progress.value = 0.0;
    } else {
      Get.back();
    }
  }

  void previousStory() {
    if (currentStoryIndex.value > 0) {
      currentStoryIndex.value--;
      progress.value = 0.0;
    } else {
      progress.value = 0.0;
    }
  }

  void pauseStory() => _isPaused = true;
  void resumeStory() => _isPaused = false;

  final ImagePicker _picker = ImagePicker();
  final Rx<File?> selectedImage = Rx<File?>(null);
  final selectedSong = Rxn<SongModel>();

  Future<void> pickStoryImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        selectedImage.value = File(image.path);
        selectedSong.value = null;
        Get.toNamed('/story-editor');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> postStory(String? text) async {
    if (selectedImage.value == null) return;

    try {
      isLoading.value = true;
      final success = await _service.createStory(
        selectedImage.value!.path,
        'image',
        caption: text,
      );

      if (success) {
        selectedImage.value = null;
        selectedSong.value = null;
        Get.offAllNamed('/home');
        Get.snackbar('Success', 'Story shared!');
      } else {
        Get.snackbar('Error', 'Failed to post story. Try again.');
      }
    } catch (e) {
      print("Story Post Error: $e");
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
