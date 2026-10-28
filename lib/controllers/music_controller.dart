import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/song_model.dart';
import '../services/api_service.dart';
import '../services/music_service.dart';

enum MusicRepeatMode { off, one, all }

class MusicController extends GetxController {
  late final MusicService _musicService;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Streams & States
  final songs = <SongModel>[].obs;
  final trendingSongs = <SongModel>[].obs;
  final likedSongs = <SongModel>[].obs;
  final queue = <SongModel>[].obs;
  final currentIndex = 0.obs;

  final isLoading = false.obs;
  final isSearching = false.obs;
  final searchQuery = ''.obs;
  final selectedLanguage = 'Hindi'.obs;
  final errorMessage = ''.obs;

  // Active Playback State
  final currentSong = Rxn<SongModel>();
  final isPlaying = false.obs;
  final isBuffering = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;

  final isShuffleOn = false.obs;
  final repeatMode = MusicRepeatMode.off.obs;

  // Selected song for post/story media
  final selectedSong = Rxn<SongModel>();

  static const List<String> availableLanguages = [
    'Hindi',
    'English',
    'Punjabi',
    'Bhojpuri',
    'Tamil',
    'Telugu',
  ];

  @override
  void onInit() {
    super.onInit();
    final apiService = Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put(ApiService(), permanent: true);
    _musicService = MusicService(apiService);

    _listenToAudioEvents();
    loadTrendingSongs();

    debounce(searchQuery, (String query) {
      if (query.trim().isNotEmpty) {
        searchSongs(query);
      } else {
        songs.assignAll(trendingSongs);
        isSearching.value = false;
      }
    }, time: const Duration(milliseconds: 200));
  }

  void _listenToAudioEvents() {
    _audioPlayer.setVolume(1.0);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        isPlaying.value = true;
        isBuffering.value = false;
      } else if (state == PlayerState.paused) {
        isPlaying.value = false;
        isBuffering.value = false;
      } else if (state == PlayerState.completed) {
        isPlaying.value = false;
        isBuffering.value = false;
        _handleTrackCompletion();
      } else if (state == PlayerState.stopped) {
        isPlaying.value = false;
        isBuffering.value = false;
      }
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      currentPosition.value = pos;
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      if (dur != Duration.zero) {
        totalDuration.value = dur;
      }
    });
  }

  void _handleTrackCompletion() {
    if (repeatMode.value == MusicRepeatMode.one && currentSong.value != null) {
      playSong(currentSong.value!, forceRestart: true);
    } else if (hasNextSong) {
      playNextSong();
    } else if (repeatMode.value == MusicRepeatMode.all && queue.isNotEmpty) {
      currentIndex.value = 0;
      playSong(queue[0]);
    } else {
      currentPosition.value = Duration.zero;
    }
  }

  bool get hasNextSong => currentIndex.value < queue.length - 1;
  bool get hasPreviousSong => currentIndex.value > 0;

  Future<void> loadTrendingSongs() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _musicService.getTrendingSongs(
        language: selectedLanguage.value,
      );
      trendingSongs.assignAll(result);
      if (!isSearching.value) {
        songs.assignAll(result);
      }
    } catch (e) {
      errorMessage.value = 'Unable to load music. Please retry.';
      debugPrint("MusicController Trending Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      songs.assignAll(trendingSongs);
      isSearching.value = false;
      return;
    }

    try {
      isSearching.value = true;
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _musicService.searchSongs(
        query,
        language: selectedLanguage.value,
      );
      songs.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Search failed. Please try again.';
      debugPrint("MusicController Search Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void changeLanguage(String lang) {
    selectedLanguage.value = lang;
    if (searchQuery.value.trim().isNotEmpty) {
      searchSongs(searchQuery.value);
    } else {
      loadTrendingSongs();
    }
  }

  Future<void> playSong(
    SongModel song, {
    List<SongModel>? newQueue,
    int? index,
    bool forceRestart = false,
  }) async {
    try {
      if (song.audioUrl.isEmpty) {
        Get.snackbar(
          'Error',
          'No audio stream available for this track',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // If clicking current song and not forcing restart
      if (!forceRestart && currentSong.value?.id == song.id) {
        if (isPlaying.value) {
          await pauseSong();
        } else {
          await resumeSong();
        }
        return;
      }

      // Set new queue if provided
      if (newQueue != null && newQueue.isNotEmpty) {
        queue.assignAll(newQueue);
        currentIndex.value = index ?? queue.indexWhere((s) => s.id == song.id);
        if (currentIndex.value == -1) currentIndex.value = 0;
      } else if (!queue.any((s) => s.id == song.id)) {
        queue.add(song);
        currentIndex.value = queue.length - 1;
      } else {
        currentIndex.value = queue.indexWhere((s) => s.id == song.id);
      }

      isBuffering.value = true;
      currentSong.value = song;
      currentPosition.value = Duration.zero;
      totalDuration.value = Duration(seconds: song.duration);

      await _audioPlayer.stop();
      if (song.audioUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(song.audioUrl));
        isPlaying.value = true;
      } else {
        Get.snackbar(
          'Error',
          'Audio stream URL is empty.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      isBuffering.value = false;
    } catch (e) {
      debugPrint("Audio Play Error for ${song.title} (${song.audioUrl}): $e");
      isBuffering.value = false;
      isPlaying.value = false;
      Get.snackbar(
        'Playback Error',
        'Could not play track. It might be restricted or broken.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> pauseSong() async {
    await _audioPlayer.pause();
    isPlaying.value = false;
  }

  Future<void> resumeSong() async {
    if (currentSong.value != null) {
      await _audioPlayer.resume();
      isPlaying.value = true;
    }
  }

  Future<void> togglePlayPause() async {
    if (currentSong.value == null && songs.isNotEmpty) {
      playSong(songs[0]);
    } else if (isPlaying.value) {
      await pauseSong();
    } else {
      await resumeSong();
    }
  }

  Future<void> playNextSong() async {
    if (queue.isEmpty) return;

    if (isShuffleOn.value && queue.length > 1) {
      int nextIdx;
      do {
        nextIdx =
            (queue.length * (DateTime.now().millisecondsSinceEpoch % 100) / 100)
                .floor();
      } while (nextIdx == currentIndex.value);
      currentIndex.value = nextIdx;
    } else if (hasNextSong) {
      currentIndex.value++;
    } else if (repeatMode.value == MusicRepeatMode.all) {
      currentIndex.value = 0;
    } else {
      return;
    }

    playSong(queue[currentIndex.value]);
  }

  Future<void> playPreviousSong() async {
    if (queue.isEmpty) return;

    if (currentPosition.value.inSeconds > 4) {
      seek(Duration.zero);
      return;
    }

    if (hasPreviousSong) {
      currentIndex.value--;
      playSong(queue[currentIndex.value]);
    } else {
      seek(Duration.zero);
    }
  }

  Future<void> seek(Duration position) async {
    currentPosition.value = position;
    await _audioPlayer.seek(position);
  }

  void toggleShuffle() {
    isShuffleOn.toggle();
    Get.snackbar(
      'Shuffle',
      isShuffleOn.value ? 'Shuffle enabled' : 'Shuffle disabled',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void toggleRepeat() {
    if (repeatMode.value == MusicRepeatMode.off) {
      repeatMode.value = MusicRepeatMode.all;
    } else if (repeatMode.value == MusicRepeatMode.all) {
      repeatMode.value = MusicRepeatMode.one;
    } else {
      repeatMode.value = MusicRepeatMode.off;
    }
    Get.snackbar(
      'Repeat',
      repeatMode.value == MusicRepeatMode.one
          ? 'Repeat One Track'
          : repeatMode.value == MusicRepeatMode.all
          ? 'Repeat All'
          : 'Repeat Off',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void toggleLikeSong(SongModel song) {
    final index = likedSongs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      likedSongs.removeAt(index);
      Get.snackbar(
        'Removed',
        'Song removed from Liked Songs',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    } else {
      likedSongs.add(song.copyWith(isLiked: true));
      Get.snackbar(
        'Liked',
        'Added to Liked Songs',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
      );
    }

    if (currentSong.value?.id == song.id) {
      currentSong.value = currentSong.value!.copyWith(
        isLiked: isSongLiked(song.id),
      );
    }
  }

  bool isSongLiked(String songId) {
    return likedSongs.any((s) => s.id == songId);
  }

  // Media Selection (for stories/posts)
  void selectSongForMedia(SongModel song) {
    selectedSong.value = song;
  }

  void clearSelection() {
    selectedSong.value = null;
  }

  // Helper formatting
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String formatDurationFromDuration(Duration duration) {
    return formatDuration(duration.inSeconds);
  }

  // Backwards compatibility
  String? get playingSongIdVal => currentSong.value?.id;

  void playPreview(SongModel song) => playSong(song);

  void stopPreview() => pauseSong();

  void selectSong(SongModel song) => selectSongForMedia(song);

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
