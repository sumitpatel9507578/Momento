import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/song_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';
import 'jamendo_service.dart';
import 'jiosaavn_service.dart';

class MusicService {
  final ApiService _apiService;
  final JioSaavnService _jioSaavnService = JioSaavnService();
  final JamendoService _jamendoService = JamendoService();

  MusicService(this._apiService);

  Future<List<SongModel>> searchSongs(
    String query, {
    String language = 'hindi',
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      // 1. Primary: Try JioSaavn API
      final saavnResults = await _jioSaavnService.searchSongs(query);
      if (saavnResults.isNotEmpty) return saavnResults;

      // 2. Secondary: Try Momento Backend API
      final url =
          "${ApiConstants.songs}/search?q=${Uri.encodeComponent(query)}";
      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songsJson = data['data'] ?? data['songs'] ?? [];
        final results = songsJson
            .whereType<Map>()
            .map((json) => SongModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        if (results.isNotEmpty) return results;
      }

      // 3. Fallback: Jamendo API
      return await _jamendoService.searchSongs(query);
    } catch (e) {
      debugPrint("MusicService search error: $e");
      return await _jamendoService.searchSongs(query);
    }
  }

  Future<List<SongModel>> getTrendingSongs({
    String language = 'hindi',
  }) async {
    try {
      // 1. Primary: Try JioSaavn API
      final saavnResults = await _jioSaavnService.getTrendingSongs(
        language: language,
      );
      if (saavnResults.isNotEmpty) return saavnResults;

      // 2. Secondary: Try Momento Backend API
      final response = await _apiService.get("${ApiConstants.songs}/trending");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songsJson = data['data'] ?? data['songs'] ?? [];
        final results = songsJson
            .whereType<Map>()
            .map((json) => SongModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        if (results.isNotEmpty) return results;
      }

      // 3. Fallback: Jamendo API
      return await _jamendoService.getPopularSongs();
    } catch (e) {
      debugPrint("MusicService trending error: $e");
      return await _jamendoService.getPopularSongs();
    }
  }
}
