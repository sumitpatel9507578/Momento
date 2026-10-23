import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/gesture_settings.dart';

class GestureSettingsService {
  static const String _storageKey = 'momento_gesture_settings_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<GestureSettings> loadSettings() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return GestureSettings.fromJson(jsonStr);
      }
    } catch (e) {
      debugPrint('Error loading gesture settings: $e');
    }
    return const GestureSettings();
  }

  Future<bool> saveSettings(GestureSettings settings) async {
    try {
      await _storage.write(key: _storageKey, value: settings.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving gesture settings: $e');
      return false;
    }
  }

  Future<void> resetToDefaults() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (e) {
      debugPrint('Error resetting gesture settings: $e');
    }
  }
}
