import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/report_model.dart';
import '../utils/api_constants.dart';
import 'api_service.dart';

class ReportService extends GetxService {
  final ApiService _apiService;

  ReportService(this._apiService);

  final List<ReportModel> _localReports = [];

  Future<bool> submitReport({
    required String targetId,
    required String targetType, // user, post, reel, comment, story
    required String reason,
    String details = '',
    String targetTitle = '',
  }) async {
    final user = await _apiService.getUser();
    final reporterId = (user?['id'] ?? user?['uid'] ?? '').toString();
    final reporterUsername = (user?['username'] ?? 'User').toString();

    final reportId = "REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

    final body = <String, dynamic>{
      'id': reportId,
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'targetTitle': targetTitle,
      'reason': reason,
      'details': details,
    };

    try {
      final response = await _apiService.post("${ApiConstants.baseUrl}/reports", body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint("ReportService submitReport server error: $e");
    }

    _localReports.add(
      ReportModel(
        id: reportId,
        reporterId: reporterId,
        reporterUsername: reporterUsername,
        targetId: targetId,
        targetType: targetType,
        targetTitle: targetTitle,
        reason: reason,
        details: details,
        status: 'open',
        createdAt: DateTime.now(),
      ),
    );

    return true;
  }

  Future<List<ReportModel>> fetchAdminReports({
    String status = 'all',
    String targetType = 'all',
  }) async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.baseUrl}/admin/reports?status=$status&targetType=$targetType",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? data['reports'] ?? [];
        return list.map((e) => ReportModel.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    } catch (e) {
      debugPrint("ReportService fetchAdminReports error: $e");
    }

    return _localReports;
  }

  Future<bool> reviewReport({
    required String reportId,
    required String action, // resolve, dismiss, review
    String adminNote = '',
  }) async {
    try {
      final response = await _apiService.post(
        "${ApiConstants.baseUrl}/admin/reports/action",
        {
          'reportId': reportId,
          'action': action,
          'adminNote': adminNote,
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint("ReportService reviewReport error: $e");
    }

    final idx = _localReports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final existing = _localReports[idx];
      String newStatus = 'open';
      if (action == 'resolve') newStatus = 'resolved';
      if (action == 'dismiss') newStatus = 'dismissed';
      if (action == 'review') newStatus = 'under_review';

      _localReports[idx] = ReportModel(
        id: existing.id,
        reporterId: existing.reporterId,
        reporterUsername: existing.reporterUsername,
        targetId: existing.targetId,
        targetType: existing.targetType,
        targetTitle: existing.targetTitle,
        reason: existing.reason,
        details: existing.details,
        status: newStatus,
        adminNote: adminNote,
        createdAt: existing.createdAt,
      );
    }

    return true;
  }
}
