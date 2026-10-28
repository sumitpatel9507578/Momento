import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/music_controller.dart';
import '../utils/app_colors.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MusicController>()) {
      return const SizedBox.shrink();
    }

    final MusicController musicController = Get.find<MusicController>();

    return Obx(() {
      final song = musicController.currentSong.value;
      if (song == null) {
        return const SizedBox.shrink();
      }

      final isPlaying = musicController.isPlaying.value;
      final currentPos = musicController.currentPosition.value;
      final totalDur = musicController.totalDuration.value;
      final double progress = (totalDur.inMilliseconds > 0)
          ? (currentPos.inMilliseconds / totalDur.inMilliseconds).clamp(
              0.0,
              1.0,
            )
          : 0.0;

      return Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Album Cover
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.imageUrl.isNotEmpty
                          ? Image.network(
                              song.imageUrl,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 42,
                                height: 42,
                                color: AppColors.purple.withValues(alpha: 0.3),
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Container(
                              width: 42,
                              height: 42,
                              color: AppColors.purple.withValues(alpha: 0.3),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Song Info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist.isNotEmpty
                                ? song.artist
                                : 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Play/Pause Button
                    IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          musicController.pauseSong();
                        } else {
                          musicController.resumeSong();
                        }
                      },
                    ),

                    // Next Button
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => musicController.playNextSong(),
                    ),
                  ],
                ),
              ),
            ),

            // Progress Bar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.purple,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
