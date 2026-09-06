import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../models/reel_model.dart';
import '../services/pexels_service.dart';

class ReelController extends GetxController {
  final PexelsService pexelsService;

  ReelController({required this.pexelsService});

  final reels = <ReelModel>[].obs;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  final _videoControllers = RxMap<String, VideoPlayerController>({});
  Map<String, VideoPlayerController> get videoControllers => _videoControllers;

  int currentPage = 1;
  bool hasMore = true;

  @override
  void onInit() {
    super.onInit();
    getReels();
  }

  Future<void> getReels() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentPage = 1;
      hasMore = true;

      final result = await pexelsService.getPopularReels(
        page: currentPage,
        perPage: 10,
      );

      reels.assignAll(result);

      if (reels.isNotEmpty) {
        await initializeVideo(0);
        await playVideo(0);
      }

      hasMore = result.length == 10;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore) return;

    try {
      isLoadingMore.value = true;

      final nextPage = currentPage + 1;

      final result = await pexelsService.getPopularReels(
        page: nextPage,
        perPage: 10,
      );

      if (result.isEmpty) {
        hasMore = false;
        return;
      }

      currentPage = nextPage;
      reels.addAll(result);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> initializeVideo(int index) async {
    if (index < 0 || index >= reels.length) return;

    final reel = reels[index];

    if (_videoControllers.containsKey(reel.id)) {
      return;
    }

    final videoController = VideoPlayerController.networkUrl(
      Uri.parse(reel.videoUrl),
    );

    _videoControllers[reel.id] = videoController;

    try {
      await videoController.initialize();
      await videoController.setLooping(true);
      _videoControllers.refresh();
    } catch (e) {
      _videoControllers.remove(reel.id);
      await videoController.dispose();
    }
  }

  Future<void> playVideo(int index) async {
    if (index < 0 || index >= reels.length) return;

    await initializeVideo(index);

    final currentReel = reels[index];
    final currentController = _videoControllers[currentReel.id];

    if (currentController == null) return;

    for (final controller in _videoControllers.values) {
      if (controller != currentController) {
        await controller.pause();
      }
    }

    if (currentController.value.isInitialized) {
      await currentController.play();
    }

    // Next reel preload
    final nextIndex = index + 1;

    if (nextIndex < reels.length) {
      await initializeVideo(nextIndex);
    }
  }

  Future<void> pauseVideo(int index) async {
    if (index < 0 || index >= reels.length) return;

    final reel = reels[index];
    final controller = _videoControllers[reel.id];

    if (controller != null) {
      await controller.pause();
    }
  }

  Future<void> togglePlayPause(int index) async {
    if (index < 0 || index >= reels.length) return;

    await initializeVideo(index);

    final reel = reels[index];
    final controller = _videoControllers[reel.id];

    if (controller == null) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await playVideo(index);
    }
  }

  VideoPlayerController? getVideoController(int index) {
    if (index < 0 || index >= reels.length) {
      return null;
    }

    final reel = reels[index];

    return _videoControllers[reel.id];
  }

  @override
  void onClose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }

    _videoControllers.clear();

    super.onClose();
  }
}
