import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String profileImage;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    this.profileImage = '',
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
  });

  factory UserModel.fromRandomUserJson(Map<String, dynamic> json) {
    final name = json['name'] ?? {};
    final picture = json['picture'] ?? {};

    return UserModel(
      uid: json['login']?['uuid'] ?? '',
      name: '${name['first'] ?? ''} ${name['last'] ?? ''}'.trim(),
      username: json['login']?['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: picture['large'] ?? '',
      bio: 'Welcome to my Momento profile.',
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
      createdAt: DateTime.now(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'] ?? '',
      bio: map['bio'] ?? '',
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String
                ? DateTime.parse(map['createdAt'])
                : (map['createdAt'] as Timestamp).toDate())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? username,
    String? email,
    String? profileImage,
    String? bio,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
