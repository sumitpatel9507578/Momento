import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/song_model.dart';

class JamendoService {
  static const String baseUrl = 'https://api.jamendo.com/v3.0/tracks/';
  static const String clientId = '8a108e0f';

  Future<List<SongModel>> getPopularSongs({
    int limit = 30,
    String language = 'hindi',
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl?client_id=$clientId&format=json&limit=$limit&order=popularity_total&audioformat=mp32&include=musicinfo',
      );
      debugPrint('Jamendo API Popular Request: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        final songs = results
            .whereType<Map>()
            .map((json) => SongModel.fromJson(Map<String, dynamic>.from(json)))
            .where((s) => s.audioUrl.isNotEmpty)
            .toList();
        if (songs.isNotEmpty) return songs;
      }
      return [];
    } catch (e) {
      debugPrint('JamendoService Popular Error: $e');
      return [];
    }
  }

  Future<List<SongModel>> searchSongs(
    String query, {
    int limit = 30,
  }) async {
    if (query.trim().isEmpty) return getPopularSongs(limit: limit);

    try {
      final url = Uri.parse(
        '$baseUrl?client_id=$clientId&format=json&search=${Uri.encodeComponent(query.trim())}&limit=$limit&audioformat=mp32&include=musicinfo',
      );
      debugPrint('Jamendo API Search Request: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        final songs = results
            .whereType<Map>()
            .map((json) => SongModel.fromJson(Map<String, dynamic>.from(json)))
            .where((s) => s.audioUrl.isNotEmpty)
            .toList();
        if (songs.isNotEmpty) return songs;
      }
      return [];
    } catch (e) {
      debugPrint('JamendoService Search Error: $e');
      return [];
    }
  }
}
