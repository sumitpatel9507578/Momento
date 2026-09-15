import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class JamendoService {
  static const String baseUrl = 'https://api.jamendo.com/v3.0/tracks/';
  static const String clientId = '8a108e0f';

  Future<List<SongModel>> getPopularSongs({int limit = 20}) async {
    try {
      final url = Uri.parse(
        '$baseUrl?client_id=$clientId&format=json&limit=$limit&order=popularity_total',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => SongModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('JamendoService Popular Error: $e');
      return [];
    }
  }

  Future<List<SongModel>> searchSongs(String query, {int limit = 20}) async {
    try {
      final url = Uri.parse(
        '$baseUrl?client_id=$clientId&format=json&search=${Uri.encodeComponent(query)}&limit=$limit',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => SongModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('JamendoService Search Error: $e');
      return [];
    }
  }
}
