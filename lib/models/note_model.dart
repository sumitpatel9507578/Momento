import 'package:flutter/foundation.dart';

class NoteModel {
  final String id;
  final String userId;
  final String username;
  final String profileImage;
  final String noteText;
  final Map<String, dynamic>? musicTrack;
  final DateTime createdAt;
  final bool isMine;

  NoteModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.noteText,
    this.musicTrack,
    required this.createdAt,
    this.isMine = false,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json, {String currentUserId = ''}) {
    final user = json['user'] is Map ? json['user'] : null;
    final uid = (json['userId'] ?? json['user_id'] ?? user?['id'] ?? user?['uid'] ?? '').toString();

    Map<String, dynamic>? parsedMusic;
    if (json['musicTrack'] is Map) {
      parsedMusic = Map<String, dynamic>.from(json['musicTrack']);
    } else if (json['song'] is Map) {
      parsedMusic = Map<String, dynamic>.from(json['song']);
    }

    return NoteModel(
      id: (json['id'] ?? json['noteId'] ?? json['_id'] ?? '').toString(),
      userId: uid,
      username: json['username'] ?? user?['username'] ?? user?['name'] ?? 'User',
      profileImage: json['profileImage'] ?? json['profile_image'] ?? user?['profileImage'] ?? user?['profile_image'] ?? '',
      noteText: (json['noteText'] ?? json['text'] ?? json['note'] ?? '').toString(),
      musicTrack: parsedMusic,
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      ).toLocal(),
      isMine: uid.isNotEmpty && uid == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'profileImage': profileImage,
      'noteText': noteText,
      'musicTrack': musicTrack,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
