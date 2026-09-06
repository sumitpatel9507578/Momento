import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/reel_model.dart';

class PexelsService {
  static const String baseUrl = 'https://api.pexels.com/videos/popular';

  final String apiKey;

  PexelsService({required this.apiKey});

  Future<List<ReelModel>> getPopularReels({
    int page = 1,
    int perPage = 10,
  }) async {
    final url = Uri.parse(baseUrl).replace(
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    final response = await http.get(url, headers: {'Authorization': apiKey});

    if (response.statusCode != 200) {
      throw Exception('Pexels API Error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    final List videos = data['videos'] ?? [];

    return videos
        .map<ReelModel>(
          (video) => ReelModel.fromJson(Map<String, dynamic>.from(video)),
        )
        .toList();
  }
}
