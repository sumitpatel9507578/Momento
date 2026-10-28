import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/home_controller.dart';
import 'package:momento/models/reel_model.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/services/reel_service.dart';
import 'package:momento/utils/api_constants.dart';
import 'package:video_player/video_player.dart';

class ReelController extends GetxController {
  final ReelService _service = Get.find<ReelService>();

  final reels = <ReelModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  final currentIndex = 0.obs;
  PageController pageController = PageController();
  final videoControllers = <String, VideoPlayerController>{};
  final failedInitializations = <String>{}.obs;

  /// Jab bhi koi video ready/dispose/fail ho, ye badhta hai.
  /// Screen ke Obx me ise read karo, tabhi UI rebuild hoga.
  final videoVersion = 0.obs;

  final savedReels = <String>{}.obs;
  final isMuted = false.obs;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _active = false; // false = screen se bahar, kuch bhi auto-play na ho
  Future<void>? _initialLoad;
  final Map<String, Future<void>> _initializing = {};

  bool _isReelsTabActive() {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>().currentIndex.value == 1;
    }
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    _initialLoad = getReels();
    // Argument handling ab screen se hota hai (openFromArguments),
    // kyunki controller persist rehta hai aur onInit sirf ek baar chalta hai.
  }

  // ---------------------------------------------------------------------------
  // Entry point: ReelsScreen.initState se HAR BAAR call karo.
  // ---------------------------------------------------------------------------
  Future<void> openFromArguments(dynamic argument) async {
    final requestedReelId = argument is ReelModel
        ? argument.id
        : argument is Map
        ? (argument['reelId'] ?? argument['id'])?.toString()
        : argument?.toString();

    if (requestedReelId != null && requestedReelId.isNotEmpty) {
      await openReel(requestedReelId);
      return;
    }

    // Koi specific reel nahi: jahan the wahin se (page controller sync karke).
    prepareOpen(currentIndex.value);
    if (reels.isEmpty) await (_initialLoad ?? Future<void>.value());
    if (reels.isNotEmpty) {
      final i = currentIndex.value.clamp(0, reels.length - 1);
      await playVideo(i);
    }
  }

  /// Page controller ko `index` par rakhta hai. PageView build hone se
  /// PEHLE sync call hota hai, isliye flash/scroll nahi dikhta.
  void prepareOpen(int index) {
    currentIndex.value = index;
    if (_isPageControllerAttached) {
      pageController.jumpToPage(index);
    } else {
      pageController.dispose();
      pageController = PageController(initialPage: index);
    }
  }

  bool get _isPageControllerAttached {
    try {
      return pageController.hasClients;
    } catch (_) {
      return false;
    }
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
      if (result.length < 10) _hasMore = false;
      // NOTE: yahan auto-play nahi. Play openFromArguments / onPageChanged se hoga,
      // warna requested reel se pehle reel 0 ki awaaz aati thi.
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
      if (_isPageControllerAttached) pageController.jumpToPage(0);
      if (reels.isNotEmpty) await playVideo(0);
    } catch (e) {
      Get.snackbar('Error', 'Unable to refresh reels');
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<bool> openReel(String reelId) async {
    // Agar reels pehle se loaded hain to yahan koi await nahi hota,
    // isliye prepareOpen sync chalta hai (first frame se sahi page).
    if (reels.isEmpty) await (_initialLoad ?? Future<void>.value());

    var index = reels.indexWhere((reel) => reel.id == reelId);
    if (index == -1) {
      try {
        final reel = await _service.fetchReelById(reelId);
        if (reel == null) {
          Get.snackbar('Unavailable', 'This reel is no longer available');
          return false;
        }
        reels.insert(0, reel);
        index = 0;
      } catch (e) {
        Get.snackbar('Error', 'Could not open this reel. Please try again.');
        return false;
      }
    }

    prepareOpen(index);
    await playVideo(index);
    return true;
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

  // ---------------------------------------------------------------------------
  // Video init (race-free: ek reel ke liye ek hi init chalta hai)
  // ---------------------------------------------------------------------------
  Future<void> initializeVideo(int index) {
    if (index < 0 || index >= reels.length) return Future<void>.value();
    final reel = reels[index];
    if (videoControllers.containsKey(reel.id) ||
        failedInitializations.contains(reel.id)) {
      return Future<void>.value();
    }
    return _initializing[reel.id] ??= _initVideo(
      reel,
    ).whenComplete(() => _initializing.remove(reel.id));
  }

  Future<void> _initVideo(ReelModel reel) async {
    final videoUrl = ApiConstants.getFullUrl(reel.videoUrl);
    final c = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await c.initialize().timeout(const Duration(seconds: 15));

      // Init ke dauraan user aage nikal gaya? To is controller ki zaroorat nahi.
      final idx = reels.indexWhere((r) => r.id == reel.id);
      if (idx == -1 || (idx - currentIndex.value).abs() > 1) {
        await c.dispose();
        return;
      }

      await c.setLooping(true);
      await c.setVolume(isMuted.value ? 0.0 : 1.0);
      videoControllers[reel.id] = c;
      failedInitializations.remove(reel.id);

      if (_active && idx == currentIndex.value && _isReelsTabActive()) {
        c.play();
      } else {
        c.pause();
      }
      videoVersion.value++;
    } catch (e) {
      debugPrint('Video init error for ${reel.id} ($videoUrl): $e');
      await c.dispose(); // pehle leak ho jata tha
      failedInitializations.add(reel.id);
      videoVersion.value++;
    }
  }

  Future<void> retryVideo(int index) async {
    if (index < 0 || index >= reels.length) return;
    failedInitializations.remove(reels[index].id);
    videoVersion.value++;
    await playVideo(index);
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------
  Future<void> playVideo(int index) async {
    if (index < 0 || index >= reels.length) return;

    currentIndex.value = index;
    final isReelsActive = _isReelsTabActive();
    _active = isReelsActive;
    final reel = reels[index];

    // Baaki sab pause (aur purani reel shuru se).
    videoControllers.forEach((id, c) {
      if (id != reel.id && c.value.isPlaying) {
        c.pause();
        c.seekTo(Duration.zero);
      }
    });

    final current = videoControllers[reel.id];
    if (current != null) {
      current.setVolume(isMuted.value ? 0.0 : 1.0);
      if (isReelsActive) {
        current.play();
      } else {
        current.pause();
      }
    } else {
      // _initVideo khud play kar dega jab ready ho (agar ab bhi current hai).
      await initializeVideo(index);
      if (currentIndex.value != index) return; // user aage nikal gaya
    }

    // Agli aur pichli dono preload (pehle sirf agli hoti thi).
    initializeVideo(index + 1);
    initializeVideo(index - 1);

    _cleanupOldControllers(index);
  }

  void _cleanupOldControllers(int currentIndex) {
    final idsToKeep = <String>{};
    for (int i = currentIndex - 1; i <= currentIndex + 1; i++) {
      if (i >= 0 && i < reels.length) idsToKeep.add(reels[i].id);
    }

    final keysToRemove = videoControllers.keys
        .where((id) => !idsToKeep.contains(id))
        .toList();
    if (keysToRemove.isEmpty) return;

    for (final key in keysToRemove) {
      final c = videoControllers.remove(key);
      // Thoda ruk ke dispose: widget ko pehle rebuild hone do,
      // warna "used after being disposed" error aata hai.
      if (c != null) {
        Future.delayed(const Duration(milliseconds: 400), c.dispose);
      }
    }
    videoVersion.value++;
  }

  void togglePlayPause(int index) {
    if (index < 0 || index >= reels.length) return;
    final controller = videoControllers[reels[index].id];
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  /// Mute global hai: sab loaded controllers par lagta hai.
  void toggleMute([int? index]) {
    isMuted.value = !isMuted.value;
    final vol = isMuted.value ? 0.0 : 1.0;
    for (final c in videoControllers.values) {
      c.setVolume(vol);
    }
  }

  void seekTo(int index, Duration position) {
    getVideoController(index)?.seekTo(position);
  }

  VideoPlayerController? getVideoController(int index) {
    if (index < 0 || index >= reels.length) return null;
    return videoControllers[reels[index].id];
  }

  void pauseAllVideos() {
    _active = false;
    for (final c in videoControllers.values) {
      c.pause();
    }
  }

  void resumeCurrentVideo() {
    if (reels.isEmpty) return;
    _active = true;
    final i = currentIndex.value.clamp(0, reels.length - 1);
    final controller = videoControllers[reels[i].id];
    if (controller != null && !controller.value.isPlaying) {
      controller.setVolume(isMuted.value ? 0.0 : 1.0);
      controller.play();
    }
  }

  Future<void> toggleLike(int index) async {
    if (index < 0 || index >= reels.length) return;

    final reel = reels[index];
    final originalState = reel.isLiked;
    final originalLikes = reel.likesCount;

    reels[index] = reel.copyWith(
      isLiked: !reel.isLiked,
      likesCount: reel.isLiked ? reel.likesCount - 1 : reel.likesCount + 1,
    );

    try {
      final success = await _service.toggleLike(reel.id);
      if (!success) {
        reels[index] = reel.copyWith(
          isLiked: originalState,
          likesCount: originalLikes,
        );
      }
    } catch (_) {
      reels[index] = reel.copyWith(
        isLiked: originalState,
        likesCount: originalLikes,
      );
    }
  }

  Future<void> deleteReel(String reelId) async {
    try {
      final success = await _service.deleteReel(reelId);
      if (success) {
        final c = videoControllers.remove(reelId);
        reels.removeWhere((r) => r.id == reelId);
        videoVersion.value++;
        if (c != null) {
          Future.delayed(const Duration(milliseconds: 400), c.dispose);
        }
        Get.snackbar('Success', 'Reel deleted successfully');
      } else {
        Get.snackbar('Error', 'Failed to delete reel');
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not delete reel');
    }
  }

  Future<void> toggleRepost(
    int index, {
    String? note,
    bool removeNote = false,
  }) async {
    if (index < 0 || index >= reels.length) return;

    final reel = reels[index];
    final originalState = reel.isReposted;
    final originalCount = reel.repostsCount;
    final originalNote = reel.repostNote;
    final originalAvatar = reel.repostUserAvatar;

    Map<String, dynamic>? currentUser;
    if (Get.isRegistered<ApiService>()) {
      currentUser = await Get.find<ApiService>().getUser();
    }
    final userAvatar =
        (currentUser?['profileImage'] ??
                currentUser?['profile_image'] ??
                currentUser?['profileimage'] ??
                currentUser?['avatar'] ??
                '')
            .toString();

    final bool newRepostedState = removeNote ? false : true;
    final newCount = newRepostedState
        ? (originalState ? originalCount : originalCount + 1)
        : (originalCount > 0 ? originalCount - 1 : 0);

    final String finalNote = (note != null && note.trim().isNotEmpty)
        ? note.trim()
        : 'Drop an emoji...';

    // Optimistic UI update
    reels[index] = reel.copyWith(
      isReposted: newRepostedState,
      repostsCount: newCount,
      repostNote: newRepostedState ? finalNote : null,
      repostUserAvatar: newRepostedState ? userAvatar : null,
    );

    Get.snackbar(
      newRepostedState ? 'Reposted' : 'Removed',
      newRepostedState ? 'Reel reposted with note!' : 'Repost removed',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: newRepostedState ? Colors.green : Colors.grey[800],
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    try {
      await _service.toggleRepost(
        reel.id,
        note: newRepostedState ? finalNote : null,
      );
    } catch (_) {
      reels[index] = reel.copyWith(
        isReposted: originalState,
        repostsCount: originalCount,
        repostNote: originalNote,
        repostUserAvatar: originalAvatar,
      );
    }
  }

  Future<void> _disposeVideos() async {
    final all = videoControllers.values.toList();
    videoControllers.clear();
    failedInitializations.clear();
    videoVersion.value++;
    for (final c in all) {
      await c.dispose();
    }
  }

  @override
  void onClose() {
    _disposeVideos();
    pageController.dispose();
    super.onClose();
  }
}
