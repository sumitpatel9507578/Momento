import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

import '../models/song_model.dart';
import '../services/jamendo_service.dart';

class MusicController extends GetxController {
  final JamendoService _jamendoService = JamendoService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final songs = <SongModel>[].obs;
  final popularSongs = <SongModel>[].obs;
  final isLoading = false.obs;
  final isSearching = false.obs;
  final searchQuery = ''.obs;

  final playingSongId = RxnString();
  final isPlaying = false.obs;
  final selectedSong = Rxn<SongModel>();
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPopularSongs();

    _audioPlayer.setVolume(1.0);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        isPlaying.value = true;
      } else if (state == PlayerState.paused) {
        isPlaying.value = false;
      } else if (state == PlayerState.completed ||
          state == PlayerState.stopped) {
        playingSongId.value = null;
        isPlaying.value = false;
      }
    });

    debounce(searchQuery, (String query) {
      if (query.trim().isNotEmpty) {
        searchSongs(query);
      } else {
        songs.assignAll(popularSongs);
        isSearching.value = false;
      }
    }, time: const Duration(milliseconds: 500));
  }

  Future<void> loadPopularSongs() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _jamendoService.getPopularSongs();
      popularSongs.assignAll(result);
      if (!isSearching.value) {
        songs.assignAll(result);
      }
    } catch (e) {
      errorMessage.value = 'Unable to load music. Please retry.';
      print("MusicController Popular Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      songs.assignAll(popularSongs);
      isSearching.value = false;
      return;
    }

    try {
      isSearching.value = true;
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _jamendoService.searchSongs(query);
      songs.assignAll(result);
    } catch (e) {
      errorMessage.value = 'Search failed. Please try again.';
      print("MusicController Search Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void playSong(SongModel song) async {
    try {
      print(
        "MusicController: Playing '${song.title}' from URL: '${song.audioUrl}'",
      );
      if (song.audioUrl.isEmpty) {
        Get.snackbar('Error', 'No audio source available for this track');
        return;
      }

      if (playingSongId.value == song.id) {
        if (isPlaying.value) {
          await pauseSong();
        } else {
          await _audioPlayer.setVolume(1.0);
          await _audioPlayer.resume();
          isPlaying.value = true;
        }
        return;
      }

      await _audioPlayer.stop();
      playingSongId.value = song.id;
      isPlaying.value = true;

      await _audioPlayer.setVolume(1.0);
      _audioPlayer.play(UrlSource(song.audioUrl)).catchError((e) {
        print("Audio Play Async Error: $e");
        if (playingSongId.value == song.id) {
          playingSongId.value = null;
          isPlaying.value = false;
        }
      });
    } catch (e) {
      print("Audio Play Error: $e");
      playingSongId.value = null;
      isPlaying.value = false;
      Get.snackbar('Error', 'Could not play audio preview');
    }
  }

  Future<void> pauseSong() async {
    await _audioPlayer.pause();
    isPlaying.value = false;
  }

  void stopSong() async {
    await _audioPlayer.stop();
    playingSongId.value = null;
    isPlaying.value = false;
  }

  // Aliases for compatibility
  void playPreview(SongModel song) => playSong(song);
  void stopPreview() => stopSong();

  void selectSong(SongModel song) {
    selectedSong.value = song;
    stopSong();
  }

  void clearSelection() {
    selectedSong.value = null;
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
