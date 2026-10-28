import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/models/song_model.dart';
import 'package:video_player/video_player.dart';

import '../controllers/home_controller.dart';
import '../controllers/music_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/reel_controller.dart';
import '../controllers/story_controller.dart';
import '../services/post_service.dart';
import '../services/reel_service.dart';
import '../services/story_service.dart';
import '../utils/app_colors.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _captionController = TextEditingController();

  late File _file;
  late bool _isVideo;
  late String _mode; // 'post' | 'story' | 'reel'

  VideoPlayerController? _videoController;
  final _isVideoInitialized = false.obs;
  final _selectedSong = Rxn<SongModel>();
  final _isUploading = false.obs;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _file = args['file'] as File;
    _isVideo = args['isVideo'] == true;
    _mode = (args['mode'] ?? 'post').toString();

    if (_isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.file(_file);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();
      _isVideoInitialized.value = true;
    } catch (e) {
      debugPrint('Error initializing video preview in UploadScreen: $e');
    }
  }

  Future<void> _onSharePressed() async {
    if (_isUploading.value) return;

    _isUploading.value = true;

    final caption = _captionController.text.trim();
    bool success = false;
    final song = _selectedSong.value;

    try {
      if (_mode == 'story') {
        final storyService = Get.find<StoryService>();
        success = await storyService.createStory(
          _file.path,
          _isVideo ? 'video' : 'image',
          caption: caption,
          songId: song?.id,
          audioUrl: song?.audioUrl,
          songTitle: song?.title,
        );
      } else if (_mode == 'reel') {
        final reelService = Get.find<ReelService>();
        success = await reelService.createReel(
          caption,
          _file.path,
          songId: song?.id,
        );
      } else {
        // Mode == 'post'
        final postService = Get.find<PostService>();
        success = await postService.createPost(
          caption,
          _file.path,
          _isVideo ? 'video' : 'image',
        );
      }

      if (success) {
        // Refresh home posts, stories, reels
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();
          homeController.changeTab(0);
          homeController.loadPosts();
        }
        if (Get.isRegistered<StoryController>()) {
          Get.find<StoryController>().loadStories();
        }
        if (Get.isRegistered<ReelController>()) {
          Get.find<ReelController>().refreshReels();
        }
        if (Get.isRegistered<ProfileController>(tag: 'me')) {
          Get.find<ProfileController>(
            tag: 'me',
          ).loadProfile(forceRefresh: true);
        }

        final modeName = _mode == 'story'
            ? 'Story'
            : (_mode == 'reel' ? 'Reel' : 'Post');
        Get.snackbar('Success', '$modeName shared successfully!');
        Get.offAllNamed('/home');
      } else {
        Get.snackbar('Error', 'Failed to share. Please try again.');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      Get.snackbar('Error', 'Upload failed: $e');
    } finally {
      _isUploading.value = false;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeTitle = _mode == 'story'
        ? 'New Story'
        : (_mode == 'reel' ? 'New Reel' : 'New Post');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          modeTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: _isUploading.value ? null : _onSharePressed,
              child: _isUploading.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.purple,
                      ),
                    )
                  : const Text(
                      'Share',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Media Preview
            Container(
              height: 380,
              width: double.infinity,
              color: Colors.grey[900],
              child: _isVideo
                  ? Obx(() => _isVideoInitialized.value && _videoController != null
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ))
                  : Image.file(_file, fit: BoxFit.cover),
            ),

            // Music Selection Tile
            Obx(
              () => ListTile(
                leading: const Icon(Icons.music_note, color: Colors.purpleAccent),
                title: Text(
                  _selectedSong.value != null
                      ? '${_selectedSong.value!.title} - ${_selectedSong.value!.artist}'
                      : 'Add Music',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () async {
                  final song = await Get.toNamed(
                    '/music',
                    arguments: {'isSelectionMode': true},
                  );
                  if (song is SongModel) {
                    _selectedSong.value = song;
                  } else if (Get.isRegistered<MusicController>() &&
                      Get.find<MusicController>().selectedSong.value != null) {
                    _selectedSong.value =
                        Get.find<MusicController>().selectedSong.value;
                  }
                },
              ),
            ),
            const Divider(color: Colors.white10),

            // Caption Input (Hidden for Story mode)
            if (_mode != 'story')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caption',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Write a caption...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
