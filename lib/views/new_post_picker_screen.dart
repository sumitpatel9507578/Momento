import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../routes/app_routes.dart';

class NewPostPickerScreen extends StatefulWidget {
  const NewPostPickerScreen({super.key});

  @override
  State<NewPostPickerScreen> createState() => _NewPostPickerScreenState();
}

class _NewPostPickerScreenState extends State<NewPostPickerScreen> {
  final ImagePicker _picker = ImagePicker();
  final Rxn<File> _file = Rxn<File>();
  final RxString _mode = 'post'.obs;
  bool _openingPicker = false;

  bool get _isVideo {
    final path = _file.value?.path.toLowerCase() ?? '';
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickMedia());
  }

  Future<void> _pickMedia() async {
    if (_openingPicker) return;
    _openingPicker = true;
    try {
      final picked = await _picker.pickMedia();
      if (mounted && picked != null) _file.value = File(picked.path);
    } catch (_) {
      if (mounted) Get.snackbar('Gallery', 'Could not open media picker.');
    } finally {
      _openingPicker = false;
    }
  }

  Future<void> _next() async {
    final file = _file.value;
    if (file == null) return _pickMedia();
    if (_mode.value == 'reel' && !_isVideo) {
      Get.snackbar('Choose a video', 'Reels need a video from your gallery.');
      return _pickMedia();
    }
    await Get.toNamed(
      AppRoutes.upload,
      arguments: {'file': file, 'isVideo': _isVideo, 'mode': _mode.value},
    );
  }

  Future<void> _selectMode(String mode) async {
    if (mode == 'live') {
      await Get.toNamed(AppRoutes.create);
      return;
    }
    _mode.value = mode;
    if (mode == 'reel' && _file.value != null && !_isVideo) await _pickMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D10),
      body: SafeArea(
        child: Obx(() {
          final file = _file.value;
          final mode = _mode.value;
          final title = mode == 'story'
              ? 'New story'
              : mode == 'reel'
              ? 'New reel'
              : 'New post';
          return Column(
            children: [
              SizedBox(
                height: 62,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: file == null ? null : _next,
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          color: Color(0xFF7895FF),
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: GestureDetector(
                    onTap: _pickMedia,
                    child: Container(
                      width: double.infinity,
                      color: Colors.black,
                      child: file == null
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.photo_library_outlined,
                                    color: Colors.white70,
                                    size: 48,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Select a photo or video',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            )
                          : _isVideo
                          ? const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 64,
                              ),
                            )
                          : Image.file(file, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Recents',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickMedia,
                      icon: const Icon(
                        Icons.check_box_outline_blank_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Select',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white24,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 74,
                child: file == null
                    ? const Center(
                        child: Text(
                          'Tap Select to browse your media',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: _isVideo
                                ? const Icon(
                                    Icons.videocam,
                                    color: Colors.white,
                                  )
                                : Image.file(file, fit: BoxFit.cover),
                          ),
                          IconButton(
                            onPressed: _pickMedia,
                            icon: const Icon(Icons.add, color: Colors.white70),
                          ),
                        ],
                      ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF15171B),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _modeButton('POST', 'post'),
                    _modeButton('STORY', 'story'),
                    _modeButton('REEL', 'reel'),
                    _modeButton('LIVE', 'live'),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _modeButton(String label, String mode) {
    final selected = _mode.value == mode;
    return GestureDetector(
      onTap: () => _selectMode(mode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
