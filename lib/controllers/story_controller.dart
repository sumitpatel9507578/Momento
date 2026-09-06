import 'package:get/get.dart';

import '../models/story_model.dart';
import '../services/fake_story_service.dart';

class StoryController extends GetxController {
  final FakeStoryService _service = FakeStoryService();

  final stories = <StoryModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // For Story Viewer
  final currentStoryIndex = 0.obs;
  final progress = 0.0.obs;
  bool _isPaused = false;

  @override
  void onInit() {
    super.onInit();
    loadStories();

    // Mark as viewed when index changes
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
      errorMessage.value = 'Unable to load stories.';
    } finally {
      isLoading.value = false;
    }
  }

  void markAsViewed(String storyId) {
    final index = stories.indexWhere((s) => s.storyId == storyId);
    if (index != -1) {
      stories[index] = stories[index].copyWith(viewed: true);
    }
  }

  bool isViewed(String storyId) {
    final story = stories.firstWhereOrNull((s) => s.storyId == storyId);
    return story?.viewed ?? false;
  }

  // Playback Methods
  void nextStory() {
    if (currentStoryIndex.value < stories.length - 1) {
      currentStoryIndex.value++;
      progress.value = 0.0;
    } else {
      Get.back(); // Close viewer if last story
    }
  }

  void previousStory() {
    if (currentStoryIndex.value > 0) {
      currentStoryIndex.value--;
      progress.value = 0.0;
    } else {
      progress.value = 0.0; // Restart current if first
    }
  }

  void pauseStory() {
    _isPaused = true;
  }

  void resumeStory() {
    _isPaused = false;
  }

  void updateProgress(double value) {
    if (!_isPaused) {
      progress.value = value;
      if (value >= 1.0) {
        nextStory();
      }
    }
  }
}
