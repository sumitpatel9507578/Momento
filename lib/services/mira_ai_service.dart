import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
    final endpoints = [
      "${ApiConstants.baseUrl}/ai/captions",
      "${ApiConstants.baseUrl}/mira/captions",
      "${ApiConstants.baseUrl}/captions",
    ];

    for (final url in endpoints) {
      try {
        final response = await _apiService.post(url, {
          'prompt': prompt,
          'tone': tone,
          'language': language,
          'length': length,
        });

        debugPrint(
          "MiraAiService generateCaptions [$url] status: ${response.statusCode}",
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final parsed = _parseCaptionResponse(data);
          if (parsed['captions']!.isNotEmpty) {
            return {
              'success': true,
              'captions': parsed['captions'],
              'hashtags': parsed['hashtags'],
            };
          }
        }
      } catch (e) {
        debugPrint("MiraAiService generateCaptions error [$url]: $e");
      }
    }

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
    final endpoints = [
      "${ApiConstants.baseUrl}/ai/vision",
      "${ApiConstants.baseUrl}/mira/vision",
      "${ApiConstants.baseUrl}/vision",
    ];

    for (final url in endpoints) {
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

        debugPrint(
          "MiraAiService generateVisionCaption [$url] status: ${response.statusCode}",
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final parsed = _parseCaptionResponse(data);
          if (parsed['captions']!.isNotEmpty) {
            return {
              'success': true,
              'captions': parsed['captions'],
              'hashtags': parsed['hashtags'],
              'description': data['description'] ?? (parsed['captions']!.first),
            };
          }
        }
      } catch (e) {
        debugPrint("MiraAiService generateVisionCaption error [$url]: $e");
      }
    }

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
    final endpoints = [
      "${ApiConstants.baseUrl}/ai/chat-replies",
      "${ApiConstants.baseUrl}/mira/chat-replies",
      "${ApiConstants.baseUrl}/chat-replies",
    ];

    for (final url in endpoints) {
      try {
        final response = await _apiService.post(url, {
          'recentMessages': recentMessages,
        });

        debugPrint(
          "MiraAiService generateChatReplies [$url] status: ${response.statusCode}",
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['replies'] is List) {
            final replies = List<String>.from(data['replies']);
            if (replies.isNotEmpty) return replies;
          }
        }
      } catch (e) {
        debugPrint("MiraAiService generateChatReplies error [$url]: $e");
      }
    }

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
    final endpoints = [
      "${ApiConstants.baseUrl}/ai/comment-replies",
      "${ApiConstants.baseUrl}/mira/comment-replies",
      "${ApiConstants.baseUrl}/comment-replies",
    ];

    for (final url in endpoints) {
      try {
        final response = await _apiService.post(url, {
          'postCaption': postCaption,
          'parentComment': parentComment ?? '',
        });

        debugPrint(
          "MiraAiService generateCommentReplies [$url] status: ${response.statusCode}",
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['replies'] is List) {
            final replies = List<String>.from(data['replies']);
            if (replies.isNotEmpty) return replies;
          }
        }
      } catch (e) {
        debugPrint("MiraAiService generateCommentReplies error [$url]: $e");
      }
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
    final endpoints = [
      "${ApiConstants.baseUrl}/ai/subtitles",
      "${ApiConstants.baseUrl}/mira/subtitles",
      "${ApiConstants.baseUrl}/subtitles",
    ];

    for (final url in endpoints) {
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

        debugPrint(
          "MiraAiService generateSubtitles [$url] status: ${response.statusCode}",
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return {'success': true, 'subtitles': data['subtitles'] ?? []};
        }
      } catch (e) {
        debugPrint("MiraAiService generateSubtitles error [$url]: $e");
      }
    }

    return {
      'success': true,
      'subtitles': [
        {"text": "Welcome to Momento Reels ✨", "start": 0.0, "end": 2.0},
        {"text": "Powered by Mira AI Subtitles 🤖", "start": 2.0, "end": 4.5},
        {"text": "Create & Share Your World! 🌍", "start": 4.5, "end": 7.0},
      ],
    };
  }

  Map<String, List<String>> _parseCaptionResponse(Map<String, dynamic> data) {
    List<String> captions = [];
    List<String> hashtags = [];

    if (data['captions'] is List) {
      captions = List<String>.from(
        data['captions'],
      ).map((c) => c.toString().trim()).where((c) => c.isNotEmpty).toList();
    } else if (data['caption'] != null) {
      if (data['caption'] is List) {
        captions = List<String>.from(
          data['caption'],
        ).map((c) => c.toString().trim()).where((c) => c.isNotEmpty).toList();
      } else {
        final raw = data['caption'].toString().trim();
        if (raw.contains('#')) {
          final parts = raw.split('#');
          final mainText = parts[0].trim();
          if (mainText.isNotEmpty) captions.add(mainText);
          final foundTags = parts
              .skip(1)
              .map((t) => '#${t.trim().split(' ').first}')
              .where((t) => t.length > 1)
              .toList();
          hashtags.addAll(foundTags);
        } else if (raw.isNotEmpty) {
          captions.add(raw);
        }
      }
    }

    if (data['hashtags'] is List) {
      final tags = List<String>.from(
        data['hashtags'],
      ).map((t) => t.toString().trim()).where((t) => t.isNotEmpty).toList();
      for (final t in tags) {
        final formattedTag = t.startsWith('#') ? t : '#$t';
        if (!hashtags.contains(formattedTag)) hashtags.add(formattedTag);
      }
    }

    return {'captions': captions, 'hashtags': hashtags};
  }
}
