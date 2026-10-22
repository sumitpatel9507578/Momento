import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/music_controller.dart';
import '../models/song_model.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicController controller = Get.find<MusicController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Add Music',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            final hasSelected = controller.selectedSong.value != null;
            return TextButton(
              onPressed: hasSelected
                  ? () => Get.back(result: controller.selectedSong.value)
                  : null,
              child: Text(
                'Done',
                style: TextStyle(
                  color: hasSelected ? AppColors.cyan : Colors.white24,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white54,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Selected Song Banner if any
          Obx(() {
            final selected = controller.selectedSong.value;
            if (selected == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Song:',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        Text(
                          '${selected.title} • ${selected.artist}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 18,
                    ),
                    onPressed: () => controller.clearSelection(),
                  ),
                ],
              ),
            );
          }),

          // Song List / Results
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.songs.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.purple),
                );
              }

              if (controller.errorMessage.value.isNotEmpty &&
                  controller.songs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white54,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.errorMessage.value,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: controller.loadPopularSongs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.songs.isEmpty) {
                return const Center(
                  child: Text(
                    'No songs found\nTry another search.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (controller.searchQuery.value.isEmpty &&
                      controller.popularSongs.isNotEmpty) ...[
                    const Text(
                      'Popular Songs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.popularSongs.length,
                        itemBuilder: (context, index) {
                          final song = controller.popularSongs[index];
                          return _buildPopularSongCard(controller, song);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'All Tracks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ...controller.songs.map((song) {
                    return _buildSongTile(controller, song);
                  }),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSongCard(MusicController controller, SongModel song) {
    return Obx(() {
      final isPlaying =
          controller.playingSongId.value == song.id &&
          controller.isPlaying.value;
      final isSelected = controller.selectedSong.value?.id == song.id;

      return GestureDetector(
        onTap: () => controller.selectSong(song),
        child: Container(
          width: 110,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      song.imageUrl,
                      width: 110,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 110,
                        height: 90,
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => controller.playSong(song),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSongTile(MusicController controller, SongModel song) {
    return Obx(() {
      final isPlaying =
          controller.playingSongId.value == song.id &&
          controller.isPlaying.value;
      final isSelected = controller.selectedSong.value?.id == song.id;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.purple.withValues(alpha: 0.15)
              : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.purple
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    song.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.playSong(song),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Colors.black38,
                      child: Center(
                        child: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              song.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${song.artist} • ${controller.formatDuration(song.duration)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                color: isSelected ? AppColors.cyan : Colors.white70,
                size: 28,
              ),
              onPressed: () => controller.selectSong(song),
            ),
            onTap: () => controller.selectSong(song),
          ),
        ),
      );
    });
  }

  void _handleSongTap(
    SongModel song,
    BuildContext context,
    bool isTrending,
    int index,
  ) {
    if (isSelectionMode) {
      if (onSongSelected != null) {
        onSongSelected!(song);
      }
      Get.back();
    } else {
      final queueList = isTrending
          ? _musicController.trendingSongs
          : _musicController.songs;
      _musicController.playSong(song, newQueue: queueList, index: index);
    }
  }
}
