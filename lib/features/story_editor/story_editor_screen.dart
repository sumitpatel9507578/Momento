import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../controllers/mira_ai_controller.dart';
import '../../utils/api_constants.dart';
import '../../utils/app_colors.dart';
import '../../utils/image_filter_utils.dart';
import 'controllers/story_editor_controller.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/filter_strip.dart';
import 'widgets/mention_sheet.dart';
import 'widgets/more_options_sheet.dart';
import 'widgets/music_picker_sheet.dart';
import 'widgets/share_bar.dart';
import 'widgets/sticker_sheet.dart';

class StoryEditorScreen extends GetView<StoryEditorController> {
  const StoryEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<StoryEditorController>()) {
      Get.put(StoryEditorController());
    }
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Media with Instagram-style horizontal swipe for live filter changes
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                final filters = ImageFilterUtils.availableFilters;
                final currentIndex = filters.indexWhere(
                  (f) =>
                      f.name.toLowerCase() ==
                      controller.selectedFilter.value.toLowerCase(),
                );
                int nextIndex = currentIndex == -1 ? 0 : currentIndex;
                if (details.primaryVelocity! < -200) {
                  // Swiped Left -> Next Filter
                  nextIndex = (nextIndex + 1) % filters.length;
                } else if (details.primaryVelocity! > 200) {
                  // Swiped Right -> Previous Filter
                  nextIndex = (nextIndex - 1 + filters.length) % filters.length;
                }
                if (nextIndex != currentIndex && currentIndex != -1) {
                  final newFilter = filters[nextIndex].name;
                  controller.setFilter(newFilter);
                  Get.rawSnackbar(
                    messageText: Text(
                      'Filter: $newFilter',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    duration: const Duration(milliseconds: 900),
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.purple.withValues(alpha: 0.8),
                    borderRadius: 20,
                    margin: const EdgeInsets.only(
                      top: 60,
                      left: 100,
                      right: 100,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                  );
                }
              },
              child: Obx(() {
                final path = controller.mediaPath;
                final isFile =
                    path.startsWith('/') ||
                    path.startsWith('file://') ||
                    path.startsWith('content://');
                String cleanPath = path;
                if (path.startsWith('file://')) {
                  cleanPath = path.replaceFirst(RegExp(r'^file://+'), '');
                  if (!Platform.isWindows && !cleanPath.startsWith('/')) {
                    cleanPath = '/$cleanPath';
                  }
                }
                final filter = controller.selectedFilter.value;
                final isVideo = _isVideoFile(cleanPath, controller.mediaType);

                Widget mediaWidget;
                if (isFile && File(cleanPath).existsSync() && isVideo) {
                  mediaWidget = _EditorVideoPreviewWidget(
                    file: File(cleanPath),
                  );
                } else if (isFile && File(cleanPath).existsSync()) {
                  mediaWidget = Image.file(File(cleanPath), fit: BoxFit.cover);
                } else {
                  mediaWidget = Image.network(
                    ApiConstants.getFullUrl(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                }

                // Apply live color matrix filter
                final matrix = ImageFilterUtils.getMatrixByName(filter);
                if (matrix != null) {
                  mediaWidget = ColorFiltered(
                    key: ValueKey('filter_${filter}_$path'),
                    colorFilter: ColorFilter.matrix(matrix),
                    child: mediaWidget,
                  );
                }

                return mediaWidget;
              }),
            ),
          ),

          // Interactive Layers (Text, Stickers, Mentions)
          Positioned.fill(
            child: Obx(
              () => Stack(
                children: controller.layers.map((layer) {
                  return Positioned(
                    left: layer.position.dx,
                    top: layer.position.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        controller.updateLayerTransform(
                          layer.id,
                          details.delta,
                          1.0,
                          0.0,
                        );
                      },
                      onTap: () => controller.selectLayer(layer.id),
                      child: Transform.scale(
                        scale: layer.scale,
                        child: Transform.rotate(
                          angle: layer.rotation,
                          child: Container(
                            padding: layer.hasBackground
                                ? const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  )
                                : EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: layer.hasBackground
                                  ? Colors.black54
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              layer.content,
                              style: TextStyle(
                                color: layer.color,
                                fontSize: layer.fontSize,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Top Bar (Back button, AI Label badge)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => controller.isAiGenerated.value
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Text(
                              '✨ AI Info',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Right-side Vertical Toolbar
          Positioned(
            right: 12,
            top: size.height * 0.08,
            bottom: 85,
            child: Obx(
              () => Align(
                alignment: Alignment.topRight,
                child: EditorToolbar(
                  onText: () => _showAddTextDialog(context),
                  onStickers: () => Get.bottomSheet(
                    StickerSheet(
                      onStickerSelected: (emoji) =>
                          controller.addStickerLayer(emoji),
                    ),
                    isScrollControlled: true,
                  ),
                  onMusic: () => Get.bottomSheet(
                    MusicPickerSheet(
                      onSongSelected: (song) => controller.setMusic(song),
                    ),
                    isScrollControlled: true,
                  ),
                  onSubtitles: controller.mediaType == 'video'
                      ? () => _generateSubtitles(context)
                      : null,
                  onRestyle: () {
                    Get.bottomSheet(
                      SafeArea(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white30,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Restyle Filters',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Obx(
                                () => FilterStrip(
                                  selectedFilter:
                                      controller.selectedFilter.value,
                                  onFilterSelected: (filter) =>
                                      controller.setFilter(filter),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      isScrollControlled: true,
                    );
                  },
                  onDraw: () => Get.snackbar('Draw', 'Drawing mode active'),
                  onEffects: () =>
                      Get.snackbar('Effects', 'Enhancements applied'),
                  onMention: () => Get.bottomSheet(
                    MentionSheet(
                      onMentionSelected: (username) =>
                          controller.addMentionLayer(username),
                    ),
                    isScrollControlled: true,
                  ),
                  onSave: () => Get.snackbar('Saved', 'Saved to gallery!'),
                  onAiLabel: () => controller.isAiGenerated.value =
                      !controller.isAiGenerated.value,
                  onMore: () => Get.bottomSheet(
                    const MoreOptionsSheet(),
                    isScrollControlled: true,
                  ),
                  isAiActive: controller.isAiGenerated.value,
                ),
              ),
            ),
          ),

          // Bottom Share Bar
          const Positioned(left: 0, right: 0, bottom: 0, child: ShareBar()),

          // Loading overlay
          Obx(
            () => controller.isLoading.value
                ? Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.purple),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  bool _isVideoFile(String path, String mediaType) {
    if (mediaType == 'video') return true;
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  void _generateSubtitles(BuildContext context) async {
    final miraController = Get.put(MiraAiController());
    Get.snackbar(
      'Mira Subtitles',
      'Transcribing video speech...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.purple.withValues(alpha: 0.8),
      colorText: Colors.white,
    );

    final subtitles = await miraController.generateSubtitles(
      controller.mediaPath,
    );
    if (subtitles.isNotEmpty) {
      for (final sub in subtitles) {
        final text = sub['text'] ?? sub['subtitle'] ?? '';
        if (text.toString().trim().isNotEmpty) {
          controller.addTextLayer(
            text: text.toString().trim(),
            hasBackground: true,
          );
        }
      }
      Get.snackbar(
        'Success',
        'Subtitles generated and added to video layers!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Notice',
        'No subtitles detected or backend transcription unconfigured.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  void _showAddTextDialog(BuildContext context) {
    final textController = TextEditingController();
    bool hasBg = false;

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Text', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type something...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                controller.addTextLayer(
                  text: textController.text.trim(),
                  hasBackground: hasBg,
                );
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _EditorVideoPreviewWidget extends StatefulWidget {
  final File file;
  const _EditorVideoPreviewWidget({required this.file});

  @override
  State<_EditorVideoPreviewWidget> createState() =>
      _EditorVideoPreviewWidgetState();
}

class _EditorVideoPreviewWidgetState extends State<_EditorVideoPreviewWidget> {
  VideoPlayerController? _controller;
  final RxBool isInitialized = false.obs;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant _EditorVideoPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    isInitialized.value = false;
    await _controller?.dispose();
    _controller = VideoPlayerController.file(widget.file);
    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();
      isInitialized.value = true;
    } catch (e) {
      debugPrint('Error initializing editor video player: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = _controller;
      if (!isInitialized.value || c == null || !c.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      );
    });
  }
}
