import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:momento/services/video_filter_service.dart';
import 'package:momento/utils/video_preset_registry.dart';

class VideoFilterPreviewScreen extends StatefulWidget {
  final File videoFile;

  const VideoFilterPreviewScreen({super.key, required this.videoFile});

  @override
  State<VideoFilterPreviewScreen> createState() =>
      _VideoFilterPreviewScreenState();
}

class _VideoFilterPreviewScreenState extends State<VideoFilterPreviewScreen> {
  late VideoPreviewController _previewController;
  late GPUFilterConfiguration _currentConfiguration;
  bool _isReady = false;
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _selectedPresetName = 'Normal';

  final List<VideoPresetItem> _presets = VideoPresetRegistry.presets;

  @override
  void initState() {
    super.initState();
    _initFilter(GPUBrightnessConfiguration(), 'Normal');
  }

  Future<void> _initFilter(GPUFilterConfiguration config, String name) async {
    setState(() {
      _isReady = false;
      _selectedPresetName = name;
    });

    try {
      _currentConfiguration = config;
      await _currentConfiguration.prepare();
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      debugPrint('VideoFilterPreviewScreen init error: $e');
    }
  }

  @override
  void dispose() {
    try {
      _previewController.dispose();
    } catch (_) {}
    try {
      _currentConfiguration.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _onExportPressed() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    final exportedFile = await VideoFilterService.exportFilteredVideo(
      inputFile: widget.videoFile,
      configuration: _currentConfiguration,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _exportProgress = progress;
          });
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isExporting = false;
    });

    if (exportedFile != null) {
      Navigator.pop(context, exportedFile);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video export failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'GPU Video Filter: $_selectedPresetName',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue, size: 28),
            onPressed: _isExporting ? null : _onExportPressed,
            tooltip: 'Apply & Export',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: _isReady
                      ? GPUVideoSurfacePreview(
                          configuration: _currentConfiguration,
                          onViewCreated: (controller, outputSizeStream) async {
                            _previewController = controller;
                            await _previewController.setVideoSource(
                              FileInputSource(widget.videoFile),
                            );
                            await _currentConfiguration.update();
                            await for (final _ in outputSizeStream) {
                              if (mounted) setState(() {});
                            }
                          },
                        )
                      : const CircularProgressIndicator(color: Colors.blue),
                ),
              ),
              Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        try {
                          _previewController.play();
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        try {
                          _previewController.pause();
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                    ),
                  ],
                ),
              ),
              Container(
                height: 110,
                color: Colors.grey[900],
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    final isSelected = _selectedPresetName == preset.name;
                    return GestureDetector(
                      onTap: () {
                        _initFilter(preset.createConfiguration(), preset.name);
                      },
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.movie_filter,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: Text(
                                preset.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
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
            ],
          ),
          if (_isExporting)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.blue),
                    const SizedBox(height: 20),
                    Text(
                      'Exporting Filtered Video...\n${(_exportProgress * 100).toInt()}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
