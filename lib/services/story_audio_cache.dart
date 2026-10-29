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
  static Directory? _audioDir;

  static Future<Directory> _getAudioDir() async {
    if (_audioDir != null && _audioDir!.existsSync()) {
      return _audioDir!;
    }
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/story_audio');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _audioDir = dir;
    return dir;
  }

  /// Fast checks if the audio file is already cached in memory or disk.
  /// Returns local file path if exists & non-empty, otherwise returns null.
  static String? getFastCachedAudioPath(String url) {
    if (url.trim().isEmpty) return null;
    var cleanUrl = url.trim();
    if (cleanUrl.startsWith('http://')) {
      cleanUrl = cleanUrl.replaceFirst('http://', 'https://');
    }

    if (_memoryCache.containsKey(cleanUrl)) {
      final cachedPath = _memoryCache[cleanUrl]!;
      if (File(cachedPath).existsSync() && File(cachedPath).lengthSync() > 0) {
        return cachedPath;
      }
    }

    if (_audioDir != null && _audioDir!.existsSync()) {
      final urlHash = md5.convert(utf8.encode(cleanUrl)).toString();
      final filePath = '${_audioDir!.path}/$urlHash.mp3';
      final file = File(filePath);
      if (file.existsSync() && file.lengthSync() > 0) {
        _memoryCache[cleanUrl] = filePath;
        return filePath;
      }
    }

    return null;
  }

  /// Asynchronously checks disk cache for cached audio.
  /// If cached, returns local file path immediately.
  /// If not cached, downloads audio using HTTP client with browser User-Agent headers,
  /// saves to disk cache, and returns local file path.
  static Future<String?> getCachedAudioPath(String url) async {
    if (url.trim().isEmpty) return null;
    var cleanUrl = url.trim();
    if (cleanUrl.startsWith('http://')) {
      cleanUrl = cleanUrl.replaceFirst('http://', 'https://');
    }

    final fastPath = getFastCachedAudioPath(cleanUrl);
    if (fastPath != null) return fastPath;

    try {
      final audioDir = await _getAudioDir();
      final urlHash = md5.convert(utf8.encode(cleanUrl)).toString();
      final filePath = '${audioDir.path}/$urlHash.mp3';
      final file = File(filePath);

      if (file.existsSync() && file.lengthSync() > 0) {
        _memoryCache[cleanUrl] = filePath;
        return filePath;
      }

      // Download audio via HTTP client with standard browser User-Agent to bypass CDN 403 blocks
      debugPrint('[STORY AUDIO CACHE] Downloading -> $cleanUrl');
      final response = await http
          .get(
            Uri.parse(cleanUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': '*/*',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        _memoryCache[cleanUrl] = filePath;
        debugPrint('[STORY AUDIO CACHE] Saved -> $filePath');
        return filePath;
      } else {
        debugPrint(
          '[STORY AUDIO CACHE] Download failed status ${response.statusCode} for $cleanUrl',
        );
      }
    } catch (e) {
      debugPrint('[STORY AUDIO CACHE] Download error for $cleanUrl: $e');
    }

    return null;
  }

  /// Preloads audio file in background and saves to disk cache for instant offline playback.
  static Future<void> preloadAudio(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    var cleanUrl = url.trim();
    if (cleanUrl.startsWith('http://')) {
      cleanUrl = cleanUrl.replaceFirst('http://', 'https://');
    }

    if (getFastCachedAudioPath(cleanUrl) != null) return;
    if (_downloadingUrls.contains(cleanUrl)) return;

    _downloadingUrls.add(cleanUrl);

    try {
      await getCachedAudioPath(cleanUrl);
    } catch (_) {
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
