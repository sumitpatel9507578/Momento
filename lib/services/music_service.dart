import 'dart:convert';

import '../models/song_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class MusicService {
  final ApiService _apiService;

  MusicService(this._apiService);

  Future<List<SongModel>> fetchSongs({String? query}) async {
    try {
      final url = query != null && query.isNotEmpty
          ? "${ApiConstants.songs}/search?q=$query"
          : ApiConstants.songs;

      final response = await _apiService.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songsJson = data['data'] ?? data['songs'] ?? [];
        return songsJson.map((json) => SongModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("MusicService Error: $e");
      return [];
    }
  }

  Future<List<SongModel>> getTrendingSongs() async {
    try {
      final response = await _apiService.get("${ApiConstants.songs}/trending");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List songsJson = data['data'] ?? data['songs'] ?? [];
        return songsJson.map((json) => SongModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("MusicService Trending Error: $e");
      return [];
    }
  }
}
