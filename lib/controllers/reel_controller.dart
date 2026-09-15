import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../models/reel_model.dart';
import '../services/reel_service.dart';
import '../utils/api_constants.dart';

class ReelController extends GetxController {
  final ReelService _service = Get.find<ReelService>();

  final reels = <ReelModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  final currentIndex = 0.obs;
  final videoControllers = <String, VideoPlayerController>{};
  final failedInitializations = <String>{}.obs;

  final savedReels = <String>{}.obs;

  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    getReels();
  }

  Future<void> getReels() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      _currentPage = 1;
      _hasMore = true;

      await _disposeVideos();
      final result = await _service.fetchReels(page: _currentPage);

      reels.assignAll(result);
      if (reels.isNotEmpty) {
        await initializeVideo(0);
        playVideo(0);
      }

      if (result.length < 10) _hasMore = false;
    } catch (e) {
      errorMessage.value = 'Failed to load reels. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshReels() async {
    try {
      isRefreshing.value = true;
      _currentPage = 1;
      _hasMore = true;

      await _disposeVideos();
      final result = await _service.fetchReels(page: _currentPage);

      reels.assignAll(result);
      currentIndex.value = 0;
      if (reels.isNotEmpty) {
        await initializeVideo(0);
        playVideo(0);
      }
    } catch (e) {
      Get.snackbar('Error', 'Unable to refresh reels');
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;

    try {
      isLoadingMore.value = true;
      _currentPage++;

      final result = await _service.fetchReels(page: _currentPage);

      if (result.isEmpty) {
        _hasMore = false;
      } else {
        final existingIds = reels.map((r) => r.id).toSet();
        final newReels = result
            .where((r) => !existingIds.contains(r.id))
            .toList();
        reels.addAll(newReels);
        if (result.length < 10) _hasMore = false;
      }
    } catch (e) {
      _currentPage--;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> initializeVideo(int index) async {
    if (index < 0 || index >= reels.length) return;

    final reel = reels[index];
    if (videoControllers.containsKey(reel.id)) return;
    if (failedInitializations.contains(reel.id)) return;

    final videoUrl = ApiConstants.getFullUrl(reel.videoUrl);
    print("ReelController: Initializing Video -> $videoUrl");
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await controller.initialize().timeout(const Duration(seconds: 15));
      await controller.setLooping(true);
      videoControllers[reel.id] = controller;
      failedInitializations.remove(reel.id);
      update(); // Update UI for initialized state
    } catch (e) {
      print("Video Init Error for ${reel.id} ($videoUrl): $e");
      failedInitializations.add(reel.id);
      update();
    }
  }

  Future<void> retryVideo(int index) async {
    if (index < 0 || index >= reels.length) return;
    final reel = reels[index];
    failedInitializations.remove(reel.id);
    update();
    await initializeVideo(index);
    playVideo(index);
  }

  void playVideo(int index) async {
    if (index < 0 || index >= reels.length) return;

    currentIndex.value = index;
    final currentReel = reels[index];

    // Ensure initialized
    if (!videoControllers.containsKey(currentReel.id)) {
      await initializeVideo(index);
    }

    final controller = videoControllers[currentReel.id];
    if (controller != null) {
      // Pause others
      videoControllers.forEach((id, ctrl) {
        if (id != currentReel.id) ctrl.pause();
      });
      controller.play();
    }

    // Preload next
    if (index + 1 < reels.length) {
      initializeVideo(index + 1);
    }

    // Cleanup old controllers (keep 3 around current)
    _cleanupOldControllers(index);
  }

  void _cleanupOldControllers(int currentIndex) {
    final idsToKeep = <String>{};
    for (int i = currentIndex - 1; i <= currentIndex + 1; i++) {
      if (i >= 0 && i < reels.length) {
        idsToKeep.add(reels[i].id);
      }
    }

    final keysToRemove = videoControllers.keys
        .where((id) => !idsToKeep.contains(id))
        .toList();
    for (var key in keysToRemove) {
      videoControllers[key]?.dispose();
      videoControllers.remove(key);
    }
  }

  void togglePlayPause(int index) {
    final reel = reels[index];
    final controller = videoControllers[reel.id];
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    update();
  }

  VideoPlayerController? getVideoController(int index) {
    if (index < 0 || index >= reels.length) return null;
    return videoControllers[reels[index].id];
  }

  void pauseAllVideos() {
    videoControllers.forEach((id, controller) {
      controller.pause();
    });
    update();
  }

  void resumeCurrentVideo() {
    if (reels.isEmpty) return;
    final reelId = reels[currentIndex.value].id;
    final controller = videoControllers[reelId];
    if (controller != null && !controller.value.isPlaying) {
      controller.play();
      update();
    }
  }

  Future<void> toggleLike(int index) async {
    if (index < 0 || index >= reels.length) return;

    final reel = reels[index];
    final originalState = reel.isLiked;
    final originalLikes = reel.likesCount;

    // Optimistic UI update
    reels[index] = reel.copyWith(
      isLiked: !reel.isLiked,
      likesCount: reel.isLiked ? reel.likesCount - 1 : reel.likesCount + 1,
    );

    try {
      final success = await _service.toggleLike(reel.id);
      if (!success) throw Exception('Failed to update like');
    } catch (e) {
      // Revert on error
      reels[index] = reel.copyWith(
        isLiked: originalState,
        likesCount: originalLikes,
      );
      Get.snackbar('Error', 'Could not update like status');
    }
  }

  bool isLiked(int index) {
    if (index < 0 || index >= reels.length) return false;
    return reels[index].isLiked;
  }

  void toggleSave(int index) {
    final reelId = reels[index].id;
    if (savedReels.contains(reelId)) {
      savedReels.remove(reelId);
    } else {
      savedReels.add(reelId);
    }
  }

  bool isSaved(String reelId) => savedReels.contains(reelId);

  Future<void> _disposeVideos() async {
    for (final controller in videoControllers.values) {
      await controller.dispose();
    }
    videoControllers.clear();
    failedInitializations.clear();
  }

  @override
  void onClose() {
    _disposeVideos();
    super.onClose();
  }
}
