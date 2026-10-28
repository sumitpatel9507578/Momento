import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:momento/models/story_model.dart';
import 'package:path_provider/path_provider.dart';

class StoryAudioCache {
  static final Map<String, String> _memoryCache = {};
  static final Set<String> _downloadingUrls = {};

  /// Synchronously or fast checks if the audio file is already cached in memory or disk.
  /// Returns local file path if exists & non-empty, otherwise returns null.
  static String? getFastCachedAudioPath(String url) {
    if (url.trim().isEmpty) return null;
    final cleanUrl = url.trim();

    if (_memoryCache.containsKey(cleanUrl)) {
      final cachedPath = _memoryCache[cleanUrl]!;
      if (File(cachedPath).existsSync() && File(cachedPath).lengthSync() > 0) {
        return cachedPath;
      }
    }
    return null;
  }

  /// Asynchronously checks disk cache for cached audio.
  /// If cached, returns local file path immediately.
  /// If not cached, triggers background download and returns null immediately.
  static Future<String?> getCachedAudioPath(String url) async {
    if (url.trim().isEmpty) return null;
    final cleanUrl = url.trim();

    final fastPath = getFastCachedAudioPath(cleanUrl);
    if (fastPath != null) return fastPath;

    try {
      final tempDir = await getTemporaryDirectory();
      final audioDir = Directory('${tempDir.path}/story_audio');
      if (!audioDir.existsSync()) {
        await audioDir.create(recursive: true);
      }

      final urlHash = md5.convert(utf8.encode(cleanUrl)).toString();
      final filePath = '${audioDir.path}/$urlHash.mp3';
      final file = File(filePath);

      if (file.existsSync() && file.lengthSync() > 0) {
        _memoryCache[cleanUrl] = filePath;
        return filePath;
      }

      // File not cached yet: trigger background download without blocking playback
      preloadAudio(cleanUrl);
    } catch (e) {
      debugPrint('[STORY AUDIO CACHE] Fast check error: $e');
    }

    return null;
  }

  /// Preloads audio file in background and saves to disk cache for instant offline playback.
  static Future<void> preloadAudio(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final cleanUrl = url.trim();

    if (getFastCachedAudioPath(cleanUrl) != null) return;
    if (_downloadingUrls.contains(cleanUrl)) return;

    _downloadingUrls.add(cleanUrl);

    try {
      final tempDir = await getTemporaryDirectory();
      final audioDir = Directory('${tempDir.path}/story_audio');
      if (!audioDir.existsSync()) {
        await audioDir.create(recursive: true);
      }

      final urlHash = md5.convert(utf8.encode(cleanUrl)).toString();
      final filePath = '${audioDir.path}/$urlHash.mp3';
      final file = File(filePath);

      if (file.existsSync() && file.lengthSync() > 0) {
        _memoryCache[cleanUrl] = filePath;
        _downloadingUrls.remove(cleanUrl);
        return;
      }

      debugPrint('[STORY AUDIO CACHE] Background downloading -> $cleanUrl');
      final response = await http
          .get(Uri.parse(cleanUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        _memoryCache[cleanUrl] = filePath;
        debugPrint('[STORY AUDIO CACHE] Saved to cache -> $filePath');
      }
    } catch (e) {
      debugPrint('[STORY AUDIO CACHE] Preload error for $cleanUrl: $e');
    } finally {
      _downloadingUrls.remove(cleanUrl);
    }
  }

  /// Batch preload audio for multiple stories
  static void preloadStoriesAudio(List<StoryModel> stories) {
    for (final story in stories) {
      if (story.audioUrl.isNotEmpty) {
        preloadAudio(story.audioUrl);
      }
    }
  }
}
