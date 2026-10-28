import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:momento/models/note_model.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/utils/api_constants.dart';

class NoteService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  NoteService(this._apiService);

  Future<List<NoteModel>> getNotes({String currentUserId = ''}) async {
    final List<NoteModel> fetchedNotes = [];

    // 1. Try server endpoints
    final endpointsToTry = [
      ApiConstants.notes,
      "${ApiConstants.baseUrl}/user-notes",
      "${ApiConstants.baseUrl}/users/notes",
      "${ApiConstants.baseUrl}/users/me/note",
    ];

    for (final endpoint in endpointsToTry) {
      try {
        final response = await _apiService.get(endpoint);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List raw =
              data['data'] ?? data['notes'] ?? (data is List ? data : []);
          for (final item in raw) {
            if (item is Map<String, dynamic>) {
              fetchedNotes.add(
                NoteModel.fromJson(item, currentUserId: currentUserId),
              );
            }
          }
          if (fetchedNotes.isNotEmpty) break;
        }
      } catch (_) {}
    }

    // 2. Local Note Fallback
    try {
      final savedJsonStr = await _storage.read(key: 'my_local_note');
      if (savedJsonStr != null && savedJsonStr.isNotEmpty) {
        final Map<String, dynamic> localJson = jsonDecode(savedJsonStr);
        final localNote = NoteModel.fromJson(
          localJson,
          currentUserId: currentUserId,
        );
        fetchedNotes.removeWhere(
          (n) => n.isMine || n.userId == localNote.userId,
        );
        fetchedNotes.insert(0, localNote);
      }
    } catch (e) {
      debugPrint('Local note read error: $e');
    }

    return fetchedNotes;
  }

  Future<NoteModel?> createNote(
    String text, {
    Map<String, dynamic>? musicTrack,
  }) async {
    final user = await _apiService.getUser();
    final userId = (user?['id'] ?? user?['uid'] ?? user?['userId'] ?? '')
        .toString();
    final username = (user?['username'] ?? user?['name'] ?? 'User').toString();
    final profileImage = (user?['profileImage'] ??
            user?['profile_image'] ??
            user?['avatar'] ??
            '')
        .toString();

    final body = <String, dynamic>{
      'noteText': text,
      'note_text': text,
      'text': text,
      'content': text,
      'note': text,
      if (musicTrack != null) 'musicTrack': musicTrack,
      if (userId.isNotEmpty) 'userId': userId,
      if (userId.isNotEmpty) 'user_id': userId,
      if (username.isNotEmpty) 'username': username,
      if (profileImage.isNotEmpty) 'profileImage': profileImage,
    };

    // 1. Try server endpoints
    final endpointsToTry = [
      ApiConstants.notes,
      "${ApiConstants.baseUrl}/user-notes",
      "${ApiConstants.baseUrl}/users/notes",
      "${ApiConstants.baseUrl}/users/me/note",
      "${ApiConstants.baseUrl}/users/me",
    ];

    for (final endpoint in endpointsToTry) {
      try {
        final response = await _apiService.post(endpoint, body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final noteJson = data['data'] ?? data['note'] ?? data;
          if (noteJson is Map<String, dynamic>) {
            return NoteModel.fromJson(noteJson, currentUserId: userId);
          }
        }
      } catch (_) {}
    }

    // 2. Hybrid Local Note Persistence Fallback
    final localNoteMap = <String, dynamic>{
      'id': 'local_note_${DateTime.now().millisecondsSinceEpoch}',
      'userId': userId,
      'user_id': userId,
      'username': username,
      'profileImage': profileImage,
      'noteText': text,
      'musicTrack': musicTrack,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await _storage.write(
        key: 'my_local_note',
        value: jsonEncode(localNoteMap),
      );
    } catch (_) {}

    return NoteModel.fromJson(localNoteMap, currentUserId: userId);
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      await _storage.delete(key: 'my_local_note');
    } catch (_) {}

    final endpointsToTry = [
      '${ApiConstants.notes}/$noteId',
      '${ApiConstants.baseUrl}/user-notes/$noteId',
      '${ApiConstants.baseUrl}/users/notes/$noteId',
      '${ApiConstants.baseUrl}/users/me/note',
    ];

    for (final endpoint in endpointsToTry) {
      try {
        final response = await _apiService.delete(endpoint);
        if (response.statusCode == 200 || response.statusCode == 204) {
          return true;
        }
      } catch (_) {}
    }

    return true;
  }
}
