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
  final bool isFollowing;
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
    this.isFollowing = false,
    required this.createdAt,
  });

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    try {
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    print("DEBUG User JSON: $map");
    final String extractedUid =
        (map['uid'] ??
                map['id'] ??
                map['_id'] ??
                map['userId'] ??
                map['user_id'] ??
                map['user']?['_id'] ??
                map['user']?['id'] ??
                '')
            .toString();

    return UserModel(
      uid: extractedUid,
      name: map['full_name'] ?? map['fullName'] ?? map['name'] ?? '',
      username: map['username'] ?? map['user_name'] ?? '',
      email: map['email'] ?? '',
      profileImage:
          map['profileImage'] ??
          map['profile_image'] ??
          map['profileimage'] ??
          map['image'] ??
          '',
      bio: map['bio'] ?? '',
      followersCount: _toInt(
        map['followersCount'] ?? map['followers_count'] ?? map['followers'],
      ),
      followingCount: _toInt(
        map['followingCount'] ?? map['following_count'] ?? map['following'],
      ),
      postsCount: _toInt(
        map['postsCount'] ?? map['posts_count'] ?? map['posts'],
      ),
      isFollowing:
          map['isFollowing'] == 1 ||
          map['isFollowing'] == true ||
          map['is_following'] == true ||
          map['following'] == true,
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'full_name': name,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isFollowing': isFollowing,
      'created_at': createdAt.toIso8601String(),
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
    bool? isFollowing,
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
      isFollowing: isFollowing ?? this.isFollowing,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
