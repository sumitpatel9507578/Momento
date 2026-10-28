import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/song_model.dart';

class JioSaavnService {
  static const List<String> _apiEndpoints = [
    'https://jiosaavn-api-private-us.vercel.app',
    'https://jiosaavn-api-v3.vercel.app',
    'https://saavn-api.vercel.app',
  ];

  static const Duration _timeout = Duration(seconds: 4);

  Future<List<SongModel>> searchSongs(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];

    final cleanQuery = Uri.encodeComponent(query.trim());

    for (final baseUrl in _apiEndpoints) {
      try {
        final url = '$baseUrl/search/songs?query=$cleanQuery&limit=$limit';
        debugPrint('JioSaavn API Search Request: $url');

        final response = await http.get(Uri.parse(url)).timeout(_timeout);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          List<dynamic>? results;

          if (data is Map) {
            if (data['data'] is Map && data['data']['results'] is List) {
              results = data['data']['results'];
            } else if (data['data'] is List) {
              results = data['data'];
            } else if (data['results'] is List) {
              results = data['results'];
            }
          }

          if (results != null && results.isNotEmpty) {
            final songs = <SongModel>[];
            for (final item in results) {
              if (item is Map) {
                try {
                  final song = SongModel.fromJson(
                    Map<String, dynamic>.from(item),
                  );
                  if (song.audioUrl.isNotEmpty) {
                    songs.add(song);
                  }
                } catch (e) {
                  debugPrint('JioSaavn parse song error: $e');
                }
              }
            }
            if (songs.isNotEmpty) return songs;
          }
        }
      } catch (e) {
        debugPrint('JioSaavn Search error on $baseUrl: $e');
      }
    }

    return [];
  }

  Future<List<SongModel>> getTrendingSongs({
    String language = 'Hindi',
    int limit = 30,
  }) async {
    final langQuery = language.trim().isEmpty ? 'Hindi' : language.trim();
    final query = '$langQuery latest trending songs';

    // Search for trending songs in specified language
    final songs = await searchSongs(query, limit: limit);
    if (songs.isNotEmpty) return songs;

    // Fallback search with language name
    return await searchSongs(langQuery, limit: limit);
  }
}
