import 'dart:convert';

import '../models/story_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class StoryService {
  final ApiService _apiService;

  StoryService(this._apiService);

  Future<List<StoryModel>> fetchStories() async {
    final response = await _apiService.get(ApiConstants.stories);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List storyJson = data['data'] ?? data['stories'] ?? [];
      return storyJson.map((json) => StoryModel.fromJson(json)).toList();
    } else {
      return [];
    }
  }

  Future<bool> createStory(
    String filePath,
    String mediaType, {
    String? caption,
  }) async {
    final response = await _apiService.postMultipart(
      ApiConstants.stories,
      {
        'mediaType': mediaType,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
      'media',
      filePath,
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> markAsViewed(String storyId) async {
    final response = await _apiService.put(
      "${ApiConstants.stories}/$storyId/view",
      {},
    );
    return response.statusCode == 200;
  }
}
