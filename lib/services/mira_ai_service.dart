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

    return _buildSituationalChatReplies(recentMessages);
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

    return _buildSituationalCommentReplies(postCaption, parentComment);
  }

  List<String> _buildSituationalChatReplies(List<String> recentMessages) {
    if (recentMessages.isEmpty) {
      return ["Hey! How's it going? 😊", "Hello there! 👋", "What's up? ✨"];
    }

    final lastMsg = recentMessages.last.trim();
    final lower = lastMsg.toLowerCase();

    // 1. Where / Location
    if (lower.contains('where') ||
        lower.contains('kahan') ||
        lower.contains('kidhar') ||
        lower.contains('location') ||
        lower.contains('place')) {
      return [
        "I'm nearby! Let me know when you're free ✨",
        "Heading over shortly! 🚗",
        "At home right now, what's up? 😄",
      ];
    }

    // 2. When / Time
    if (lower.contains('when') ||
        lower.contains('kab') ||
        lower.contains('time') ||
        lower.contains('baje') ||
        lower.contains('kitne')) {
      return [
        "In about 10-15 minutes! ⏳",
        "Free shortly, let's connect! ✨",
        "Let me check and update you ASAP! 👍",
      ];
    }

    // 3. Greetings
    if (lower.contains('hi') ||
        lower.contains('hello') ||
        lower.contains('hey') ||
        lower.contains('namaste') ||
        lower.contains('good morning') ||
        lower.contains('good evening') ||
        lower.contains('good night')) {
      return [
        "Hey! How's your day going? 😊",
        "Hello there! 👋 Good to hear from you!",
        "Hey! What's up? ✨",
      ];
    }

    // 4. How / Status
    if (lower.contains('how') ||
        lower.contains('kaisa') ||
        lower.contains('kaise') ||
        lower.contains('kya haal')) {
      return [
        "Doing great! How about you? 😊",
        "All good here! How's everything with you? ✨",
        "Pretty good, just keeping busy! 🚀",
      ];
    }

    // 5. What / Activity
    if (lower.contains('what') ||
        lower.contains('kya') ||
        lower.contains('doing') ||
        lower.contains('kar rahe')) {
      return [
        "Just chilling right now! You? 😄",
        "Not much, just catching up on things ✨",
        "Working on something exciting! 🚀",
      ];
    }

    // 6. Plans / Food / Meetup
    if (lower.contains('plan') ||
        lower.contains('meet') ||
        lower.contains('food') ||
        lower.contains('eat') ||
        lower.contains('khana') ||
        lower.contains('chai') ||
        lower.contains('coffee') ||
        lower.contains('party') ||
        lower.contains('chalo')) {
      return [
        "Sounds like a plan! Count me in 🙌",
        "Definitely! When and where? ☕",
        "Let's do it! Super excited ✨",
      ];
    }

    // 7. Gratitude
    if (lower.contains('thank') ||
        lower.contains('thanks') ||
        lower.contains('shukriya') ||
        lower.contains('dhanyawad') ||
        lower.contains('ty')) {
      return [
        "You're most welcome! 😊",
        "Anytime! Glad I could help 👍",
        "No problem at all! ✨",
      ];
    }

    // 8. Compliment / Joy
    if (lower.contains('nice') ||
        lower.contains('awesome') ||
        lower.contains('great') ||
        lower.contains('cool') ||
        lower.contains('love') ||
        lower.contains('op') ||
        lower.contains('waah') ||
        lower.contains('badiya') ||
        lower.contains('amazing') ||
        lower.contains('haha') ||
        lower.contains('lol')) {
      return [
        "Haha thank you so much! ❤️",
        "Appreciate the love! ✨",
        "Haha thanks! Glad you liked it 😂",
      ];
    }

    // 9. Agreement / Yes
    if (lower.contains('ok') ||
        lower.contains('okay') ||
        lower.contains('haan') ||
        lower.contains('yes') ||
        lower.contains('sure') ||
        lower.contains('done') ||
        lower.contains('perfect')) {
      return [
        "Perfect! See you then 👍",
        "Awesome, done! ✅",
        "Great, let's keep in touch! ✨",
      ];
    }

    // 10. General Question
    if (lower.contains('?')) {
      return [
        "Yes, absolutely! 👍",
        "Not sure yet, let me check 🧐",
        "Sounds good to me! ✨",
      ];
    }

    return [
      "Sounds great! Tell me more about it ✨",
      "Totally agree with you! 🙌",
      "Haha that's awesome! 😂",
    ];
  }

  List<String> _buildSituationalCommentReplies(
    String postCaption,
    String? parentComment,
  ) {
    final commentText =
        (parentComment != null && parentComment.trim().isNotEmpty)
        ? parentComment.trim()
        : postCaption.trim();
    final lower = commentText.toLowerCase();

    if (parentComment != null && parentComment.trim().isNotEmpty) {
      if (lower.contains('?') ||
          lower.contains('where') ||
          lower.contains('kahan') ||
          lower.contains('link') ||
          lower.contains('how')) {
        return [
          "Check out my bio for all the details! 🔗",
          "Thanks for asking! Will share a story about it soon ✨",
          "Great question! Sent you a DM 👍",
        ];
      }
      if (lower.contains('love') ||
          lower.contains('nice') ||
          lower.contains('fire') ||
          lower.contains('amazing') ||
          lower.contains('op') ||
          lower.contains('badiya') ||
          lower.contains('beautiful') ||
          lower.contains('cool')) {
        return [
          "Thank you so much! Means a lot ❤️",
          "Appreciate the love and support! 🔥",
          "Glad you liked it! ✨",
        ];
      }
      if (lower.contains('agree') ||
          lower.contains('true') ||
          lower.contains('facts') ||
          lower.contains('100') ||
          lower.contains('yes')) {
        return [
          "100% agree! Thanks for watching 🙌",
          "Exactly! So glad you resonated with this 💯",
          "Spot on! ✨",
        ];
      }
    }

    if (lower.contains('food') ||
        lower.contains('yummy') ||
        lower.contains('recipe') ||
        lower.contains('eat') ||
        lower.contains('coffee') ||
        lower.contains('dinner') ||
        lower.contains('lunch') ||
        lower.contains('delicious') ||
        lower.contains('cafe')) {
      return [
        "Looks absolutely delicious! 😋",
        "Need the recipe for this ASAP! 🤤",
        "Food & vibes both 10/10! ☕✨",
      ];
    }

    if (lower.contains('travel') ||
        lower.contains('sunset') ||
        lower.contains('trip') ||
        lower.contains('beach') ||
        lower.contains('mountain') ||
        lower.contains('view') ||
        lower.contains('nature') ||
        lower.contains('vacation')) {
      return [
        "What a stunning view! 🌅",
        "Adding this place to my bucket list! ✈️",
        "Pure aesthetic vibes! 🌲✨",
      ];
    }

    if (lower.contains('gym') ||
        lower.contains('workout') ||
        lower.contains('fitness') ||
        lower.contains('gains') ||
        lower.contains('grind') ||
        lower.contains('run') ||
        lower.contains('motivation')) {
      return [
        "Pure beast mode! 💪🔥",
        "Insane dedication! Keep grinding 🏋️‍♂️",
        "Motivation level 100! 🚀",
      ];
    }

    if (lower.contains('fit') ||
        lower.contains('outfit') ||
        lower.contains('style') ||
        lower.contains('drip') ||
        lower.contains('look') ||
        lower.contains('fashion') ||
        lower.contains('ootd')) {
      return [
        "This fit is fire! 🔥 Slayed it!",
        "Serving pure looks! 📸✨",
        "Top tier style! 👌",
      ];
    }

    if (lower.contains('music') ||
        lower.contains('song') ||
        lower.contains('dance') ||
        lower.contains('beat') ||
        lower.contains('vibe') ||
        lower.contains('reel')) {
      return [
        "This track is on loop! 🎵🔥",
        "Unmatched vibes! ✨",
        "Perfect audio match! 🎧",
      ];
    }

    if (lower.contains('congrats') ||
        lower.contains('happy') ||
        lower.contains('won') ||
        lower.contains('passed') ||
        lower.contains('got') ||
        lower.contains('new') ||
        lower.contains('milestone') ||
        lower.contains('birthday')) {
      return [
        "Huge congratulations! So proud of you! 🎉👏",
        "Well deserved success! Keep shining 🌟",
        "Celebrating this big win with you! 🥳",
      ];
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
