import 'package:get/get.dart';

import '../services/mira_ai_service.dart';

class MiraAiController extends GetxController {
  final MiraAiService _aiService = MiraAiService();

  final RxBool isLoadingCaptions = false.obs;
  final RxBool isLoadingVision = false.obs;
  final RxBool isLoadingSubtitles = false.obs;

  final RxList<String> generatedCaptions = <String>[].obs;
  final RxList<String> generatedHashtags = <String>[].obs;
  final RxString visionDescription = ''.obs;

  final RxString selectedTone = 'Engaging'.obs;
  final RxString selectedLanguage = 'English'.obs;
  final RxString selectedLength = 'Medium'.obs;

  final List<String> availableTones = [
    'Engaging',
    'Funny',
    'Professional',
    'Romantic',
    'Poetic',
    'Casual',
  ];

  final List<String> availableLanguages = [
    'English',
    'Hindi',
    'Hinglish',
    'Bhojpuri',
    'Punjabi',
  ];

  final List<String> availableLengths = [
    'Short',
    'Medium',
    'Detailed',
  ];

  Future<bool> generateCaptions(String prompt) async {
    if (prompt.trim().isEmpty) return false;

    isLoadingCaptions.value = true;
    try {
      final res = await _aiService.generateCaptions(
        prompt: prompt,
        tone: selectedTone.value.toLowerCase(),
        language: selectedLanguage.value,
        length: selectedLength.value.toLowerCase(),
      );

      if (res['success'] == true) {
        generatedCaptions.assignAll(List<String>.from(res['captions']));
        generatedHashtags.assignAll(List<String>.from(res['hashtags']));
        return true;
      }
    } finally {
      isLoadingCaptions.value = false;
    }
    return false;
  }

  Future<bool> generateVisionCaption(String imagePath) async {
    if (imagePath.isEmpty) return false;

    isLoadingVision.value = true;
    try {
      final res = await _aiService.generateVisionCaption(
        imagePath: imagePath,
        tone: selectedTone.value.toLowerCase(),
        language: selectedLanguage.value,
      );

      if (res['success'] == true) {
        generatedCaptions.assignAll(List<String>.from(res['captions']));
        generatedHashtags.assignAll(List<String>.from(res['hashtags']));
        visionDescription.value = res['description'] ?? '';
        return true;
      }
    } finally {
      isLoadingVision.value = false;
    }
    return false;
  }

  Future<List<String>> generateChatReplies({
    required List<String> recentMessages,
  }) async {
    return await _aiService.generateChatReplies(
      recentMessages: recentMessages,
    );
  }

  Future<List<String>> generateCommentReplies({
    required String postCaption,
    String? parentComment,
  }) async {
    return await _aiService.generateCommentReplies(
      postCaption: postCaption,
      parentComment: parentComment,
    );
  }

  Future<List<dynamic>> generateSubtitles(String mediaPath) async {
    isLoadingSubtitles.value = true;
    try {
      final res = await _aiService.generateSubtitles(mediaPath: mediaPath);
      if (res['success'] == true) {
        return res['subtitles'] ?? [];
      }
    } finally {
      isLoadingSubtitles.value = false;
    }
    return [];
  }
}
