import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/app_colors.dart';

class MusicPickerSheet extends StatelessWidget {
  final Function(Map<String, dynamic> song) onSongSelected;

  MusicPickerSheet({super.key, required this.onSongSelected});

  final dummySongs = [
    {'title': 'Blinding Lights', 'artist': 'The Weeknd', 'duration': '0:30'},
    {'title': 'Levitating', 'artist': 'Dua Lipa', 'duration': '0:30'},
    {'title': 'As It Was', 'artist': 'Harry Styles', 'duration': '0:30'},
    {
      'title': 'Stay',
      'artist': 'The Kid LAROI, Justin Bieber',
      'duration': '0:30',
    },
    {'title': 'Heat Waves', 'artist': 'Glass Animals', 'duration': '0:30'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.5,
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
                'Add Music',
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search music...',
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
            child: ListView.builder(
              itemCount: dummySongs.length,
              itemBuilder: (context, index) {
                final song = dummySongs[index];
                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.purpleAccent,
                    ),
                  ),
                  title: Text(
                    song['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    song['artist']!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      onSongSelected(song);
                      Get.back();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
