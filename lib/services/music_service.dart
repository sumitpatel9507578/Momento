import 'package:flutter/foundation.dart';

import '../models/song_model.dart';
import 'api_service.dart';
import 'jamendo_service.dart';
import 'jiosaavn_service.dart';

class MusicService {
  final JamendoService _jamendoService = JamendoService();
  final JioSaavnService _jioSaavnService = JioSaavnService();

  MusicService(ApiService apiService);

  Future<List<SongModel>> searchSongs(
    String query, {
    String language = 'hindi',
  }) async {
    if (query.trim().isEmpty) return getTrendingSongs(language: language);

    try {
      // 1. Primary: Jamendo API
      final jamendoResults = await _jamendoService.searchSongs(query);
      if (jamendoResults.isNotEmpty) return jamendoResults;

      // 2. Secondary Fallback: JioSaavn API
      return await _jioSaavnService.searchSongs(query);
    } catch (e) {
      debugPrint("MusicService search error: $e");
      return await _jioSaavnService.searchSongs(query);
    }
  }

  Future<List<SongModel>> getTrendingSongs({String language = 'hindi'}) async {
    try {
      // 1. Primary: Jamendo API
      final jamendoResults = await _jamendoService.getPopularSongs(
        language: language,
      );
      if (jamendoResults.isNotEmpty) return jamendoResults;

      // 2. Secondary Fallback: JioSaavn API
      return await _jioSaavnService.getTrendingSongs(language: language);
    } catch (e) {
      debugPrint("MusicService trending error: $e");
      return await _jioSaavnService.getTrendingSongs(language: language);
    }
  }
}
