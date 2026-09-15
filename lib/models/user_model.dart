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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    print("DEBUG User JSON: $map");
    return UserModel(
      uid: (map['uid'] ?? map['id'] ?? map['userId'] ?? map['user_id'] ?? '')
          .toString(),
      name: map['full_name'] ?? map['fullName'] ?? map['name'] ?? '',
      username: map['username'] ?? map['user_name'] ?? '',
      email: map['email'] ?? '',
      profileImage:
          map['profileImage'] ??
          map['profile_image'] ??
          map['profileimage'] ??
          '',
      bio: map['bio'] ?? '',
      followersCount: map['followersCount'] ?? map['followers_count'] ?? 0,
      followingCount: map['followingCount'] ?? map['following_count'] ?? 0,
      postsCount: map['postsCount'] ?? map['posts_count'] ?? 0,
      isFollowing:
          map['isFollowing'] == 1 ||
          map['isFollowing'] == true ||
          map['is_following'] == true,
      createdAt: map['created_at'] != null || map['createdAt'] != null
          ? (map['created_at'] is String || map['createdAt'] is String
                ? DateTime.parse(map['created_at'] ?? map['createdAt'])
                : DateTime.now())
          : DateTime.now(),
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
