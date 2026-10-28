import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/utils/image_filter_utils.dart';
import 'package:video_player/video_player.dart';

class VideoFilterPreviewScreen extends StatefulWidget {
  final File videoFile;

  const VideoFilterPreviewScreen({super.key, required this.videoFile});

  @override
  State<VideoFilterPreviewScreen> createState() =>
      _VideoFilterPreviewScreenState();
}

class _VideoFilterPreviewScreenState extends State<VideoFilterPreviewScreen> {
  VideoPlayerController? _controller;
  final _isInitialized = false.obs;
  final _isPlaying = false.obs;
  final _selectedFilterName = 'Normal'.obs;

  final List<ImageFilterSpec> _filters = ImageFilterUtils.availableFilters;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.file(widget.videoFile);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();
      _isInitialized.value = true;
      _isPlaying.value = true;
    } catch (e) {
      debugPrint('Error initializing video player for filter preview: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onExportPressed() {
    Navigator.pop(context, widget.videoFile);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filterName = _selectedFilterName.value;
      final matrix = ImageFilterUtils.getMatrixByName(filterName);

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            'Video Filter: $filterName',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.blue, size: 28),
              onPressed: _onExportPressed,
              tooltip: 'Apply Filter',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: _isInitialized.value && _controller != null
                    ? GestureDetector(
                        onTap: () {
                          if (_controller!.value.isPlaying) {
                            _controller!.pause();
                            _isPlaying.value = false;
                          } else {
                            _controller!.play();
                            _isPlaying.value = true;
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            matrix != null
                                ? ColorFiltered(
                                    colorFilter: ColorFilter.matrix(matrix),
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _controller!.value.size.width,
                                        height: _controller!.value.size.height,
                                        child: VideoPlayer(_controller!),
                                      ),
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _controller!.value.size.width,
                                      height: _controller!.value.size.height,
                                      child: VideoPlayer(_controller!),
                                    ),
                                  ),
                            if (!_isPlaying.value)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.blue),
              ),
            ),
            Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_controller != null && _isInitialized.value) {
                        _controller!.play();
                        _isPlaying.value = true;
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_controller != null && _isInitialized.value) {
                        _controller!.pause();
                        _isPlaying.value = false;
                      }
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                ],
              ),
            ),
            Container(
              height: 120,
              color: Colors.grey[900],
              child: SafeArea(
                top: false,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filterSpec = _filters[index];
                    final name = filterSpec.name;
                    final isSelected = filterName == name;
                    final itemMatrix = ImageFilterUtils.getMatrixByName(name);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _selectedFilterName.value = name;
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.purple : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.purpleAccent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: itemMatrix != null
                                    ? ColorFiltered(
                                        colorFilter: ColorFilter.matrix(
                                          itemMatrix,
                                        ),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFFFF7E5F),
                                                Color(0xFFFEB47B),
                                                Color(0xFF86A8E7),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFFF7E5F),
                                              Color(0xFFFEB47B),
                                              Color(0xFF86A8E7),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
