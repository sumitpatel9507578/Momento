import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/music_controller.dart';
import 'package:momento/models/song_model.dart';
import 'package:momento/utils/app_colors.dart';

class MusicPickerSheet extends StatelessWidget {
  final Function(Map<String, dynamic> song) onSongSelected;

  MusicPickerSheet({super.key, required this.onSongSelected});

  @override
  Widget build(BuildContext context) {
    final musicController = Get.isRegistered<MusicController>()
        ? Get.find<MusicController>()
        : Get.put(MusicController());

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Music to Story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (val) => musicController.searchQuery.value = val,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search songs or artists...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final songList = musicController.isSearching.value
                  ? musicController.songs
                  : (musicController.trendingSongs.isNotEmpty
                      ? musicController.trendingSongs
                      : musicController.songs);

              if (musicController.isLoading.value && songList.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.purple),
                );
              }

              if (songList.isEmpty) {
                return const Center(
                  child: Text(
                    'No songs found',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return ListView.builder(
                itemCount: songList.length,
                itemBuilder: (context, index) {
                  final SongModel song = songList[index];
                  void selectThisSong() {
                    Get.back();
                    onSongSelected(song.toJson());
                  }

                  return Obx(() {
                    final isPlaying =
                        musicController.playingSongIdVal == song.id &&
                        musicController.isPlaying.value;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: song.imageUrl.isNotEmpty
                              ? Image.network(
                                  song.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.darkGrey,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.purpleAccent,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppColors.darkGrey,
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.purpleAccent,
                                  ),
                                ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        song.artist.isNotEmpty ? song.artist : 'Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Play/Pause Preview Button
                          IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: Colors.purpleAccent,
                              size: 32,
                            ),
                            onPressed: () {
                              musicController.playSong(song);
                            },
                          ),
                          const SizedBox(width: 4),
                          // Select Button
                          ElevatedButton(
                            onPressed: selectThisSong,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                            ),
                            child: const Text(
                              'Select',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
