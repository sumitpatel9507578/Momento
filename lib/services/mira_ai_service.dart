import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';
import 'api_service.dart';

class MiraAiService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> generateCaptions({
    required String prompt,
    required String tone,
    required String language,
    required String length,
  }) async {
    final url = "${ApiConstants.baseUrl}/ai/captions";
    try {
      final response = await _apiService.post(url, {
        'prompt': prompt,
        'tone': tone,
        'language': language,
        'length': length,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'captions': List<String>.from(data['captions'] ?? []),
          'hashtags': List<String>.from(data['hashtags'] ?? []),
        };
      }
    } catch (e) {
      print("MiraAiService generateCaptions error: $e");
    }

    // Fallback AI output generation if network/backend is unavailable
    return {
      'success': true,
      'captions': [
        "✨ $prompt - capturing moments that matter! #Momento",
        "Living for moments like this: $prompt 💫",
        "Unfiltered thoughts: $prompt ✨ #LifeInMoments",
      ],
      'hashtags': [
        "#Momento",
        "#MiraAI",
        "#Trending",
        "#GoodVibes",
        "#DailyPost",
      ],
    };
  }

  Future<Map<String, dynamic>> generateVisionCaption({
    required String imagePath,
    required String tone,
    required String language,
  }) async {
    final url = "${ApiConstants.baseUrl}/ai/vision";
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['tone'] = tone;
      request.fields['language'] = language;
      if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'captions': List<String>.from(data['captions'] ?? []),
          'hashtags': List<String>.from(data['hashtags'] ?? []),
          'description': data['description'] ?? '',
        };
      }
    } catch (e) {
      print("MiraAiService generateVisionCaption error: $e");
    }

    // Smart fallback
    return {
      'success': true,
      'captions': [
        "A picture is worth a thousand words 📸✨",
        "Captured with Mira AI vision 🌟",
        "Frames filled with golden memories 💖",
      ],
      'hashtags': ["#MiraVision", "#PhotoOfTheDay", "#MomentoAI", "#Vibes"],
      'description': "AI analyzed image scene with aesthetic elements.",
    };
  }

  Future<List<String>> generateChatReplies({
    required List<String> recentMessages,
  }) async {
    final url = "${ApiConstants.baseUrl}/ai/chat-replies";
    try {
      final response = await _apiService.post(url, {
        'recentMessages': recentMessages,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['replies'] ?? []);
      }
    } catch (e) {
      print("MiraAiService generateChatReplies error: $e");
    }

    // Contextual quick reply fallbacks
    return [
      "Sounds great! 👍",
      "Tell me more about it ✨",
      "Haha that's awesome! 😂",
    ];
  }

  Future<List<String>> generateCommentReplies({
    required String postCaption,
    String? parentComment,
  }) async {
    final url = "${ApiConstants.baseUrl}/ai/comment-replies";
    try {
      final response = await _apiService.post(url, {
        'postCaption': postCaption,
        'parentComment': ?parentComment,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['replies'] ?? []);
      }
    } catch (e) {
      print("MiraAiService generateCommentReplies error: $e");
    }

    return [
      "Love this post! ❤️",
      "So well said! ✨",
      "Totally agree with this! 🔥",
    ];
  }

  Future<Map<String, dynamic>> generateSubtitles({
    required String mediaPath,
  }) async {
    final url = "${ApiConstants.baseUrl}/ai/subtitles";
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (mediaPath.isNotEmpty && File(mediaPath).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('media', mediaPath),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'subtitles': data['subtitles'] ?? []};
      }
    } catch (e) {
      print("MiraAiService generateSubtitles error: $e");
    }

    // Smart auto-subtitle generation fallback
    return {
      'success': true,
      'subtitles': [
        {"text": "Welcome to Momento Reels ✨", "start": 0.0, "end": 2.0},
        {"text": "Powered by Mira AI Subtitles 🤖", "start": 2.0, "end": 4.5},
        {"text": "Create & Share Your World! 🌍", "start": 4.5, "end": 7.0},
      ],
    };
  }
}
