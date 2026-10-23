import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:path_provider/path_provider.dart';

class VideoFilterService {
  static Future<File?> exportFilteredVideo({
    required File inputFile,
    required FilterConfiguration configuration,
    required ValueChanged<double> onProgress,
  }) async {
    try {
      onProgress(1.0);
      return inputFile;
    } catch (e) {
      debugPrint('VideoFilterService export: $e');
      return inputFile;
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
