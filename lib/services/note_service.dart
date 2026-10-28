import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:momento/models/note_model.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/utils/api_constants.dart';

class NoteService {
  final ApiService _apiService;

  NoteService(this._apiService);

  Future<List<NoteModel>> getNotes({String currentUserId = ''}) async {
    try {
      final response = await _apiService.get(ApiConstants.notes);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw =
            data['data'] ?? data['notes'] ?? (data is List ? data : []);
        return raw
            .map(
              (json) => NoteModel.fromJson(json, currentUserId: currentUserId),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('NoteService getNotes error: $e');
    }
    return [];
  }

  Future<NoteModel?> createNote(
    String text, {
    Map<String, dynamic>? musicTrack,
  }) async {
    try {
      final response = await _apiService.post(ApiConstants.notes, {
        'noteText': text,
        'musicTrack': ?musicTrack,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final noteJson = data['data'] ?? data['note'] ?? data;
        return NoteModel.fromJson(noteJson);
      }
    } catch (e) {
      debugPrint('NoteService createNote error: $e');
    }
    return null;
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.notes}/$noteId',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('NoteService deleteNote error: $e');
      return false;
    }
  }
}
