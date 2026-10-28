import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:momento/models/song_model.dart';
import 'package:momento/models/story_model.dart';
import 'package:momento/repositories/user_repository.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/services/story_audio_cache.dart';
import 'package:momento/services/story_service.dart';
import 'package:momento/utils/image_filter_utils.dart';

class StoryController extends GetxController {
  final StoryService _service = Get.find<StoryService>();
  final UserRepository _userRepository = Get.put(UserRepository());

  final stories =
      <StoryModel>[].obs; // flat stories for backward compatibility if needed
  final userStories = <UserStories>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final currentUserStoriesIndex = 0.obs;
  final currentStoryIndex = 0.obs;
  final progress = 0.0.obs;
  bool _isPaused = false;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    loadStories();

    ever(currentStoryIndex, (int index) {
      if (userStories.isNotEmpty &&
          currentUserStoriesIndex.value >= 0 &&
          currentUserStoriesIndex.value < userStories.length) {
        final currentGroup = userStories[currentUserStoriesIndex.value];
        if (index >= 0 && index < currentGroup.stories.length) {
          markAsViewed(currentGroup.stories[index].storyId);
        }
      } else if (stories.isNotEmpty && index >= 0 && index < stories.length) {
        markAsViewed(stories[index].storyId);
      }
    });
  }

  Future<void> loadStories() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final rawStories = await _service.fetchStories();
      final userId = await Get.find<ApiService>().getUserId() ?? '';

      // Fetch following list
      List<String> followingIds = [];
      if (userId.isNotEmpty) {
        try {
          final followingList = await _userRepository.getFollowing(userId);
          followingIds = followingList.map((u) => u.uid).toList();
        } catch (e) {
          if (kDebugMode) print("Error fetching following for stories: $e");
        }
      }

      final grouped = groupStories(rawStories, userId, followingIds.toSet());
      userStories.assignAll(grouped);

      // Flatten for legacy stories list
      final flat = <StoryModel>[];
      for (final us in grouped) {
        flat.addAll(us.stories);
      }
      stories.assignAll(flat);

      // Preload audio files in background for instant playback when opening stories
      StoryAudioCache.preloadStoriesAudio(flat);
    } catch (e) {
      errorMessage.value = 'No stories yet.';
    } finally {
      isLoading.value = false;
    }
  }

  List<UserStories> groupStories(
    List<StoryModel> rawStories,
    String currentUserId,
    Set<String> followingIds,
  ) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));

    final seenStoryIds = <String>{};
    final validStories = <StoryModel>[];

    for (final story in rawStories) {
      if (seenStoryIds.contains(story.storyId)) continue;
      seenStoryIds.add(story.storyId);

      // Check 24 hours
      if (story.timestamp.isBefore(cutoff)) continue;

      validStories.add(story);
    }

    // Group by userId
    final Map<String, List<StoryModel>> groupedMap = {};
    final Map<String, String> userNames = {};
    final Map<String, String> userImages = {};

    for (final story in validStories) {
      groupedMap.putIfAbsent(story.userId, () => []).add(story);
      userNames[story.userId] = story.username;
      userImages[story.userId] = story.profileImage;
    }

    final List<UserStories> userStoriesList = [];
    groupedMap.forEach((userId, userStoryList) {
      // Sort stories timestamp ascending (oldest first)
      userStoryList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      userStoriesList.add(
        UserStories(
          userId: userId,
          username: userNames[userId] ?? 'User',
          profileImage: userImages[userId] ?? '',
          stories: userStoryList,
        ),
      );
    });

    // Sort list: own story first, then unseen, then latest
    userStoriesList.sort((a, b) => _compareUserStories(a, b, currentUserId));

    return userStoriesList;
  }

  int _compareUserStories(UserStories a, UserStories b, String currentUserId) {
    final bool aIsMe = a.userId == currentUserId;
    final bool bIsMe = b.userId == currentUserId;

    if (aIsMe && !bIsMe) return -1;
    if (!aIsMe && bIsMe) return 1;

    final bool aUnseen = !a.allViewed;
    final bool bUnseen = !b.allViewed;

    if (aUnseen && !bUnseen) return -1;
    if (!aUnseen && bUnseen) return 1;

    return b.latest.compareTo(a.latest);
  }

  void markAsViewed(String storyId) async {
    for (int i = 0; i < userStories.length; i++) {
      final us = userStories[i];
      final sIdx = us.stories.indexWhere((s) => s.storyId == storyId);
      if (sIdx != -1 && !us.stories[sIdx].viewed) {
        final updatedStories = List<StoryModel>.from(us.stories);
        updatedStories[sIdx] = updatedStories[sIdx].copyWith(viewed: true);
        userStories[i] = UserStories(
          userId: us.userId,
          username: us.username,
          profileImage: us.profileImage,
          stories: updatedStories,
        );
        await _service.markAsViewed(storyId);
        break;
      }
    }
  }

  Future<void> toggleLikeStory(String storyId) async {
    for (int i = 0; i < userStories.length; i++) {
      final us = userStories[i];
      final sIdx = us.stories.indexWhere((s) => s.storyId == storyId);
      if (sIdx != -1) {
        final current = us.stories[sIdx];
        final newLiked = !current.isLiked;
        final newCount = newLiked
            ? current.likesCount + 1
            : (current.likesCount - 1).clamp(0, 99999);
        final updatedStories = List<StoryModel>.from(us.stories);
        updatedStories[sIdx] = current.copyWith(
          isLiked: newLiked,
          likesCount: newCount,
        );
        userStories[i] = UserStories(
          userId: us.userId,
          username: us.username,
          profileImage: us.profileImage,
          stories: updatedStories,
        );
        await _service.toggleLikeStory(storyId);
        break;
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchStoryViewers(String storyId) async {
    return await _service.fetchStoryViewers(storyId);
  }

  Future<bool> deleteStory(String storyId) async {
    for (int i = 0; i < userStories.length; i++) {
      final us = userStories[i];
      final sIdx = us.stories.indexWhere((s) => s.storyId == storyId);
      if (sIdx != -1) {
        final updatedStories = List<StoryModel>.from(us.stories)
          ..removeAt(sIdx);
        if (updatedStories.isEmpty) {
          userStories.removeAt(i);
          if (currentUserStoriesIndex.value >= userStories.length) {
            currentUserStoriesIndex.value = (userStories.length - 1).clamp(
              0,
              999,
            );
          }
          if (userStories.isEmpty) {
            Get.back();
          }
        } else {
          userStories[i] = UserStories(
            userId: us.userId,
            username: us.username,
            profileImage: us.profileImage,
            stories: updatedStories,
          );
          if (currentStoryIndex.value >= updatedStories.length) {
            currentStoryIndex.value = updatedStories.length - 1;
          }
        }
        break;
      }
    }

    final success = await _service.deleteStory(storyId);
    if (success) {
      Get.snackbar(
        'Deleted',
        'Story deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return success;
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
    if (userStories.isEmpty) {
      Get.back();
      return;
    }
    final currentGroup = userStories[currentUserStoriesIndex.value];
    if (currentStoryIndex.value < currentGroup.stories.length - 1) {
      currentStoryIndex.value++;
      progress.value = 0.0;
    } else {
      if (currentUserStoriesIndex.value < userStories.length - 1) {
        currentUserStoriesIndex.value++;
        currentStoryIndex.value =
            userStories[currentUserStoriesIndex.value].firstUnviewedIndex;
        progress.value = 0.0;
      } else {
        Get.back();
      }
    }
  }

  void previousStory() {
    if (currentStoryIndex.value > 0) {
      currentStoryIndex.value--;
      progress.value = 0.0;
    } else {
      if (currentUserStoriesIndex.value > 0) {
        currentUserStoriesIndex.value--;
        final prevGroup = userStories[currentUserStoriesIndex.value];
        currentStoryIndex.value = prevGroup.stories.length - 1;
        progress.value = 0.0;
      } else {
        progress.value = 0.0;
      }
    }
  }

  void pauseStory() => _isPaused = true;
  void resumeStory() => _isPaused = false;

  final ImagePicker _picker = ImagePicker();
  final Rx<File?> selectedImage = Rx<File?>(null);
  final selectedSong = Rxn<SongModel>();
  final selectedFilter = 'Normal'.obs;

  Future<void> pickStoryImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );
      if (image != null) {
        selectedImage.value = File(image.path);
        selectedSong.value = null;
        selectedFilter.value = 'Normal';
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
      String uploadPath = selectedImage.value!.path;

      if (selectedFilter.value != 'Normal') {
        uploadPath = await ImageFilterUtils.processImageWithFilter(
          inputPath: selectedImage.value!.path,
          filterName: selectedFilter.value,
        );
      }

      final song = selectedSong.value;
      debugPrint('STORY SONG -> ${song?.title} | ${song?.audioUrl}');

      final String? songTitleFormatted = (song != null && song.title.isNotEmpty)
          ? '${song.title}${song.artist.isNotEmpty ? ' • ${song.artist}' : ''}'
          : null;

      final success = await _service.createStory(
        uploadPath,
        'image',
        caption: text,
        songId: song?.id,
        audioUrl: song?.audioUrl,
        songTitle: songTitleFormatted,
      );

      if (success) {
        if (uploadPath != selectedImage.value!.path) {
          try {
            final tempFile = File(uploadPath);
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          } catch (_) {}
        }

        selectedImage.value = null;
        selectedSong.value = null;
        selectedFilter.value = 'Normal';
        await loadStories();
        Get.offAllNamed('/home');
      } else {
        Get.snackbar('Error', 'Failed to post story. Try again.');
      }
    } catch (e) {
      debugPrint("Story Post Error: $e");
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
