import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:momento/models/verification_application_model.dart';

import '../models/user_model.dart';
import '../models/verification_eligibility_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class VerificationService extends GetxService {
  final ApiService _apiService;

  VerificationService(this._apiService);

  VerificationApplicationModel? _currentLocalApplication;

  Future<VerificationEligibilityModel> checkEligibility(UserModel user) async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.baseUrl}/verification/eligibility",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final map = data is Map<String, dynamic>
            ? (data['data'] ?? data)
            : data;
        return VerificationEligibilityModel.fromMap(
          Map<String, dynamic>.from(map),
        );
      }
    } catch (e) {
      debugPrint(
        "VerificationService checkEligibility server error: $e. Using local check.",
      );
    }

    final now = DateTime.now();
    final accountAgeDays = now.difference(user.createdAt).inDays;
    final isFollowersEligible = user.followersCount >= 5000;
    final isAgeEligible = accountAgeDays >= 90;
    final isProfileComplete =
        user.name.trim().isNotEmpty &&
        user.username.trim().isNotEmpty &&
        user.bio.trim().isNotEmpty &&
        user.profileImage.trim().isNotEmpty;
    final hasActiveStanding = true;

    return VerificationEligibilityModel(
      followersCount: user.followersCount,
      minFollowersRequired: 5000,
      isFollowersEligible: isFollowersEligible,
      accountAgeDays: accountAgeDays,
      minAccountAgeDaysRequired: 90,
      isAgeEligible: isAgeEligible,
      isProfileComplete: isProfileComplete,
      hasActiveStanding: hasActiveStanding,
      isEligible:
          isFollowersEligible &&
          isAgeEligible &&
          isProfileComplete &&
          hasActiveStanding,
      canRequestException: true,
      missingRequirements: [
        if (!isFollowersEligible)
          'Minimum 5,000 genuine followers required (You have ${user.followersCount}).',
        if (!isAgeEligible)
          'Account age must be at least 90 days (Current age: $accountAgeDays days).',
        if (!isProfileComplete)
          'Profile completion required (Name, Username, Bio, and Profile Image).',
      ],
    );
  }

  Future<VerificationApplicationModel?> fetchMyApplicationStatus() async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.baseUrl}/verification/status",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final map = data is Map<String, dynamic>
            ? (data['data'] ?? data['application'] ?? data)
            : data;
        if (map is Map) {
          _currentLocalApplication = VerificationApplicationModel.fromMap(
            Map<String, dynamic>.from(map),
          );
          return _currentLocalApplication;
        }
      }
    } catch (e) {
      debugPrint("VerificationService fetchStatus error: $e");
    }
    return _currentLocalApplication;
  }

  Future<bool> submitApplication({
    required String legalName,
    required String displayName,
    required String category,
    required String country,
    required String reason,
    required String websiteUrl,
    required String documentType,
    required String documentFilePath,
  }) async {
    final user = await _apiService.getUser();
    final userId = (user?['id'] ?? user?['uid'] ?? '').toString();
    final userName = (user?['name'] ?? user?['full_name'] ?? 'User').toString();
    final userHandle = (user?['username'] ?? 'user').toString();
    final userEmail = (user?['email'] ?? '').toString();

    final appId =
        "APP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

    final fields = <String, String>{
      'id': appId,
      'userId': userId,
      'legalName': legalName,
      'displayName': displayName,
      'category': category,
      'country': country,
      'reason': reason,
      'websiteUrl': websiteUrl,
      'documentType': documentType,
    };

    try {
      await _apiService.postMultipart(
        "${ApiConstants.baseUrl}/verification/apply",
        fields,
        'document',
        documentFilePath,
      );
    } catch (e) {
      debugPrint("VerificationService submitApplication server error: $e");
    }

    _currentLocalApplication = VerificationApplicationModel(
      id: appId,
      userId: userId,
      userName: userName,
      userHandle: userHandle,
      userAvatar: user?['profileImage'] ?? '',
      userEmail: userEmail,
      legalName: legalName,
      displayName: displayName,
      category: category,
      country: country,
      reason: reason,
      websiteUrl: websiteUrl,
      documentType: documentType,
      documentUrl: documentFilePath,
      status: 'submitted',
      submittedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return true;
  }

  Future<bool> resubmitApplication({
    required String appId,
    required String updatedNotes,
    String? newDocumentFilePath,
  }) async {
    try {
      final fields = <String, String>{'appId': appId, 'notes': updatedNotes};
      if (newDocumentFilePath != null && newDocumentFilePath.isNotEmpty) {
        await _apiService.postMultipart(
          "${ApiConstants.baseUrl}/verification/resubmit",
          fields,
          'document',
          newDocumentFilePath,
        );
      } else {
        await _apiService.post(
          "${ApiConstants.baseUrl}/verification/resubmit",
          fields,
        );
      }
    } catch (e) {
      debugPrint("VerificationService resubmit error: $e");
    }

    if (_currentLocalApplication != null) {
      _currentLocalApplication = VerificationApplicationModel(
        id: _currentLocalApplication!.id,
        userId: _currentLocalApplication!.userId,
        userName: _currentLocalApplication!.userName,
        userHandle: _currentLocalApplication!.userHandle,
        userAvatar: _currentLocalApplication!.userAvatar,
        userEmail: _currentLocalApplication!.userEmail,
        legalName: _currentLocalApplication!.legalName,
        displayName: _currentLocalApplication!.displayName,
        category: _currentLocalApplication!.category,
        country: _currentLocalApplication!.country,
        reason: _currentLocalApplication!.reason,
        websiteUrl: _currentLocalApplication!.websiteUrl,
        documentType: _currentLocalApplication!.documentType,
        documentUrl:
            newDocumentFilePath ?? _currentLocalApplication!.documentUrl,
        status: 'under_review',
        adminNote: updatedNotes,
        submittedAt: _currentLocalApplication!.submittedAt,
        updatedAt: DateTime.now(),
      );
    }
    return true;
  }

  Future<Map<String, int>> fetchAdminStats() async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.baseUrl}/admin/verification/stats",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final map = data['data'] ?? data;
        return {
          'total': (map['total'] ?? 0) as int,
          'pending': (map['pending'] ?? 0) as int,
          'under_review': (map['under_review'] ?? 0) as int,
          'needs_info': (map['needs_info'] ?? 0) as int,
          'approved': (map['approved'] ?? 0) as int,
          'rejected': (map['rejected'] ?? 0) as int,
          'revoked': (map['revoked'] ?? 0) as int,
        };
      }
    } catch (e) {
      debugPrint("VerificationService fetchAdminStats error: $e");
    }

    return {
      'total': _currentLocalApplication != null ? 1 : 0,
      'pending': (_currentLocalApplication?.status == 'submitted') ? 1 : 0,
      'under_review': (_currentLocalApplication?.status == 'under_review')
          ? 1
          : 0,
      'needs_info':
          (_currentLocalApplication?.status == 'additional_info_required')
          ? 1
          : 0,
      'approved': (_currentLocalApplication?.status == 'approved') ? 1 : 0,
      'rejected': (_currentLocalApplication?.status == 'rejected') ? 1 : 0,
      'revoked': (_currentLocalApplication?.status == 'revoked') ? 1 : 0,
    };
  }

  Future<List<VerificationApplicationModel>> fetchAdminApplications({
    String status = 'all',
    String search = '',
  }) async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.baseUrl}/admin/verification/applications?status=$status&search=$search",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['applications'] ?? [];
        return list
            .map(
              (e) => VerificationApplicationModel.fromMap(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint("VerificationService fetchAdminApplications error: $e");
    }

    if (_currentLocalApplication != null) {
      return [_currentLocalApplication!];
    }
    return [];
  }

  Future<bool> reviewApplication({
    required String appId,
    required String action, // approve, reject, request_info, revoke
    String reasonNote = '',
  }) async {
    try {
      final response = await _apiService.post(
        "${ApiConstants.baseUrl}/admin/verification/review",
        {'appId': appId, 'action': action, 'reason': reasonNote},
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint("VerificationService reviewApplication error: $e");
    }

    if (_currentLocalApplication != null &&
        _currentLocalApplication!.id == appId) {
      String newStatus = 'under_review';
      if (action == 'approve') newStatus = 'approved';
      if (action == 'reject') newStatus = 'rejected';
      if (action == 'request_info') newStatus = 'additional_info_required';
      if (action == 'revoke') newStatus = 'revoked';

      _currentLocalApplication = VerificationApplicationModel(
        id: _currentLocalApplication!.id,
        userId: _currentLocalApplication!.userId,
        userName: _currentLocalApplication!.userName,
        userHandle: _currentLocalApplication!.userHandle,
        userAvatar: _currentLocalApplication!.userAvatar,
        userEmail: _currentLocalApplication!.userEmail,
        legalName: _currentLocalApplication!.legalName,
        displayName: _currentLocalApplication!.displayName,
        category: _currentLocalApplication!.category,
        country: _currentLocalApplication!.country,
        reason: _currentLocalApplication!.reason,
        websiteUrl: _currentLocalApplication!.websiteUrl,
        documentType: _currentLocalApplication!.documentType,
        documentUrl: _currentLocalApplication!.documentUrl,
        status: newStatus,
        adminNote: reasonNote,
        submittedAt: _currentLocalApplication!.submittedAt,
        updatedAt: DateTime.now(),
      );
    }
    return true;
  }
}
