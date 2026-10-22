import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/home_controller.dart';
import 'package:momento/controllers/profile_controller.dart';
import 'package:momento/controllers/reel_controller.dart';
import 'package:momento/controllers/story_controller.dart';
import 'package:momento/features/story_editor/models/editor_layer.dart';
import 'package:momento/features/story_editor/models/story_draft.dart';
import 'package:momento/services/reel_service.dart';
import 'package:momento/services/story_service.dart';
import 'package:momento/utils/image_filter_utils.dart';

class StoryEditorController extends GetxController {
  StoryService get _storyService => Get.find<StoryService>();
  ReelService get _reelService => Get.find<ReelService>();

  late String mediaPath;
  late String mediaType; // 'image' or 'video'
  late String contentType; // 'story' or 'reel'

  final isReelMode = false.obs;

  final layers = <EditorLayer>[].obs;
  final RxnString selectedLayerId = RxnString();

  final selectedMusic = Rxn<Map<String, dynamic>>();
  final mentions = <String>[].obs;
  final selectedFilter = 'Normal'.obs;
  final isAiGenerated = false.obs;
  final isCloseFriends = false.obs;
  final isYourStory = true.obs;
  final hideFromUserIds = <String>[].obs;
  final allowReplies = true.obs;
  final allowSharing = true.obs;
  final altText = ''.obs;

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    late String rawContentType;

    if (args is Map) {
      mediaPath = args['mediaPath'] ?? '';
      mediaType = args['mediaType'] ?? 'image';
      rawContentType = args['contentType'] ?? 'story';
    } else if (args is String && args.isNotEmpty) {
      mediaPath = args;
      mediaType = mediaPath.toLowerCase().endsWith('.mp4') ? 'video' : 'image';
      rawContentType = 'story';
    } else if (Get.isRegistered<StoryController>() &&
        Get.find<StoryController>().selectedImage.value != null) {
      mediaPath = Get.find<StoryController>().selectedImage.value!.path;
      mediaType = mediaPath.toLowerCase().endsWith('.mp4') ? 'video' : 'image';
      rawContentType = 'story';
    } else {
      mediaPath = '';
      mediaType = 'image';
      rawContentType = 'story';
    }

    contentType = rawContentType;
    isReelMode.value = (contentType == 'reel');
  }

  void addTextLayer({
    required String text,
    Color color = Colors.white,
    double fontSize = 28.0,
    bool hasBackground = false,
  }) {
    final layer = EditorLayer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LayerType.text,
      content: text,
      color: color,
      fontSize: fontSize,
      hasBackground: hasBackground,
    );
    layers.add(layer);
    selectedLayerId.value = layer.id;
  }

  void addStickerLayer(String emoji) {
    final layer = EditorLayer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LayerType.sticker,
      content: emoji,
      fontSize: 48.0,
    );
    layers.add(layer);
    selectedLayerId.value = layer.id;
  }

  void addMentionLayer(String username) {
    final mentionText = '@$username';
    if (!mentions.contains(username)) {
      mentions.add(username);
    }
    final layer = EditorLayer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LayerType.mention,
      content: mentionText,
      color: Colors.white,
      hasBackground: true,
      fontSize: 22.0,
    );
    layers.add(layer);
    selectedLayerId.value = layer.id;
  }

  void removeLayer(String id) {
    layers.removeWhere((l) => l.id == id);
    if (selectedLayerId.value == id) {
      selectedLayerId.value = null;
    }
  }

  void selectLayer(String? id) {
    selectedLayerId.value = id;
  }

  void updateLayerTransform(
    String id,
    Offset delta,
    double scaleFactor,
    double rotationFactor,
  ) {
    final index = layers.indexWhere((l) => l.id == id);
    if (index != -1) {
      final layer = layers[index];
      layer.position += delta;
      layer.scale = (layer.scale * scaleFactor).clamp(0.5, 4.0);
      layer.rotation += rotationFactor;
      layers[index] = layer;
    }
  }

  void setMusic(Map<String, dynamic>? music) {
    selectedMusic.value = music;
  }

  void setFilter(String filterName) {
    selectedFilter.value = filterName;
  }

  Future<void> uploadContent() async {
    if (mediaPath.isEmpty) return;

    try {
      isLoading.value = true;
      final draft = StoryDraft(
        mediaPath: mediaPath,
        mediaType: mediaType,
        layers: layers,
        selectedMusic: selectedMusic.value,
        mentions: mentions,
        selectedFilter: selectedFilter.value,
        isAiGenerated: isAiGenerated.value,
        isCloseFriends: isCloseFriends.value,
        hideFromUserIds: hideFromUserIds,
        allowReplies: allowReplies.value,
        allowSharing: allowSharing.value,
        altText: altText.value,
      );

      final captionText = draft.layers.isNotEmpty
          ? draft.layers.first.content
          : (isReelMode.value ? 'New Reel' : 'New Story');

      String uploadPath = draft.mediaPath;

      // Apply filter to actual image pixels before uploading
      if (mediaType == 'image' && draft.selectedFilter != 'Normal') {
        uploadPath = await ImageFilterUtils.processImageWithFilter(
          inputPath: draft.mediaPath,
          filterName: draft.selectedFilter,
        );
      }

      bool success = false;

      if (isReelMode.value) {
        String? songId;
        if (selectedMusic.value != null) {
          songId =
              selectedMusic.value!['id']?.toString() ??
              selectedMusic.value!['songId']?.toString();
        }
        success = await _reelService.createReel(
          captionText,
          uploadPath,
          songId: songId,
        );
      } else {
        success = await _storyService.createStory(
          uploadPath,
          draft.mediaType,
          caption: captionText,
        );
      }

      if (success) {
        // Clean up temporary file after successful upload
        if (uploadPath != draft.mediaPath) {
          try {
            final tempFile = File(uploadPath);
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          } catch (_) {}
        }

        if (isReelMode.value) {
          if (Get.isRegistered<ReelController>()) {
            Get.find<ReelController>().refreshReels();
          }
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().loadPosts();
          }
          if (Get.isRegistered<ProfileController>(tag: 'me')) {
            Get.find<ProfileController>(
              tag: 'me',
            ).loadProfile(forceRefresh: true);
          }
          Get.offAllNamed('/home');
          Get.snackbar('Success', 'Reel uploaded successfully!');
        } else {
          if (Get.isRegistered<StoryController>()) {
            Get.find<StoryController>().loadStories();
          }
          Get.offAllNamed('/home');
          Get.snackbar('Success', 'Story uploaded successfully!');
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to upload ${isReelMode.value ? 'reel' : 'story'}. Try again.',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadStory() async {
    await uploadContent();
  }
}
