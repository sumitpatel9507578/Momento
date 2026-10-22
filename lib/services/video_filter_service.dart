import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:path_provider/path_provider.dart';

class VideoFilterService {
  static Future<File?> exportFilteredVideo({
    required File inputFile,
    required GPUFilterConfiguration configuration,
    required ValueChanged<double> onProgress,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint(
        'VideoFilterService: Android-only backend. Returning original file on iOS/desktop.',
      );
      return inputFile;
    }

    try {
      await configuration.prepare();
      final tempDir = await getTemporaryDirectory();
      final outputFileName =
          'filtered_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final outputFile = File('${tempDir.path}/$outputFileName');

      if (await outputFile.exists()) {
        await outputFile.delete();
      }

      final exportConfig = VideoExportConfig(
        FileInputSource(inputFile),
        outputFile,
      );

      final stream = configuration.exportVideoFile(exportConfig);
      await for (final progress in stream) {
        onProgress(progress);
      }

      if (await outputFile.exists()) {
        return outputFile;
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('VideoFilterService export error: $e\n$stackTrace');
      return null;
    } finally {
      try {
        await configuration.dispose();
      } catch (_) {}
    }
  }

  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.contains('filtered_')) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }
}
