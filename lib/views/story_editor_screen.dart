import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/story_controller.dart';
import '../features/story_editor/widgets/filter_strip.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import 'package:momento/utils/image_filter_utils.dart';
import '../widgets/glass_container.dart';

class StoryEditorScreen extends StatefulWidget {
  const StoryEditorScreen({super.key});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final StoryController controller = Get.find<StoryController>();
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Selected Image with Live Filter Preview
          Obx(() {
            final imageFile = controller.selectedImage.value;
            if (imageFile == null) {
              return const Center(
                child: Text(
                  'No image selected',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final filterName = controller.selectedFilter.value;
            final matrix = ImageFilterUtils.getMatrixByName(filterName);

            Widget imageWidget = Image.file(
              imageFile,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );

            if (matrix != null) {
              imageWidget = ColorFiltered(
                colorFilter: ColorFilter.matrix(matrix),
                child: imageWidget,
              );
            }

            return Center(child: imageWidget);
          }),

          // Overlays
          Center(
            child: TextField(
              controller: textController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
              decoration: const InputDecoration(
                hintText: 'Add text...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),

          // Selected Song Overlay on Story
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Obx(() {
              final song = controller.selectedSong.value;
              if (song == null) return const SizedBox.shrink();
              return Center(
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: AppColors.cyan,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${song.title} • ${song.artist}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => controller.selectedSong.value = null,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Spacer(),
                  // Add Music Button in header
                  IconButton(
                    onPressed: () async {
                      final song = await Get.toNamed(AppRoutes.musicPicker);
                      if (song != null) {
                        controller.selectedSong.value = song;
                      }
                    },
                    icon: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Selection Bar
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Obx(
              () => FilterStrip(
                selectedFilter: controller.selectedFilter.value,
                onFilterSelected: (filter) {
                  controller.selectedFilter.value = filter;
                },
              ),
            ),
          ),

          // Bottom Actions
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => controller.postStory(textController.text),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
