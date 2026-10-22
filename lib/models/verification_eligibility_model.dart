class VerificationEligibilityModel {
  final int followersCount;
  final int minFollowersRequired;
  final bool isFollowersEligible;
  final int accountAgeDays;
  final int minAccountAgeDaysRequired;
  final bool isAgeEligible;
  final bool isProfileComplete;
  final bool hasActiveStanding;
  final bool isEligible;
  final bool canRequestException;
  final List<String> missingRequirements;

  VerificationEligibilityModel({
    required this.followersCount,
    this.minFollowersRequired = 5000,
    required this.isFollowersEligible,
    required this.accountAgeDays,
    this.minAccountAgeDaysRequired = 90,
    required this.isAgeEligible,
    required this.isProfileComplete,
    required this.hasActiveStanding,
    required this.isEligible,
    this.canRequestException = false,
    required this.missingRequirements,
  });

  factory VerificationEligibilityModel.fromMap(Map<String, dynamic> map) {
    final followers = _toInt(map['followersCount'] ?? map['followers_count']);
    final minFollowers = _toInt(
      map['minFollowers'] ?? map['min_followers'],
      defaultValue: 5000,
    );
    final ageDays = _toInt(map['accountAgeDays'] ?? map['account_age_days']);
    final minAgeDays = _toInt(
      map['minAccountAgeDays'] ?? map['min_account_age_days'],
      defaultValue: 90,
    );

    final followersEligible =
        map['isFollowersEligible'] ?? (followers >= minFollowers);
    final ageEligible = map['isAgeEligible'] ?? (ageDays >= minAgeDays);
    final profileComplete =
        map['isProfileComplete'] == true || map['profile_complete'] == true;
    final activeStanding =
        map['hasActiveStanding'] != false && map['active_standing'] != false;

    final missing = <String>[];
    if (!followersEligible) {
      missing.add(
        'Minimum $minFollowers genuine followers required (You have $followers).',
      );
    }
    if (!ageEligible) {
      missing.add(
        'Account must be at least $minAgeDays days old (Current age: $ageDays days).',
      );
    }
    if (!profileComplete) {
      missing.add(
        'Profile details (Name, Username, Profile Picture, Bio) must be completed.',
      );
    }
    if (!activeStanding) {
      missing.add(
        'Account must be active and in good policy standing with no critical violations.',
      );
    }

    final eligible =
        map['isEligible'] ??
        (followersEligible && ageEligible && profileComplete && activeStanding);

    return VerificationEligibilityModel(
      followersCount: followers,
      minFollowersRequired: minFollowers,
      isFollowersEligible: followersEligible,
      accountAgeDays: ageDays,
      minAccountAgeDaysRequired: minAgeDays,
      isAgeEligible: ageEligible,
      isProfileComplete: profileComplete,
      hasActiveStanding: activeStanding,
      isEligible: eligible,
      canRequestException:
          map['canRequestException'] == true ||
          map['can_request_exception'] == true,
      missingRequirements: missing,
    );
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
