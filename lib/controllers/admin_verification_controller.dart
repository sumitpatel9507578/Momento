import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/models/verification_application_model.dart';
import 'package:momento/services/verification_service.dart';

class AdminVerificationController extends GetxController {
  VerificationService get _service => Get.find<VerificationService>();

  final stats = <String, int>{
    'total': 0,
    'pending': 0,
    'under_review': 0,
    'needs_info': 0,
    'approved': 0,
    'rejected': 0,
    'revoked': 0,
  }.obs;

  final applications = <VerificationApplicationModel>[].obs;
  final selectedStatus = 'all'.obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      final newStats = await _service.fetchAdminStats();
      stats.assignAll(newStats);

      final list = await _service.fetchAdminApplications(
        status: selectedStatus.value,
        search: searchQuery.value,
      );
      applications.assignAll(list);
    } catch (e) {
      debugPrint("AdminVerificationController error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void filterByStatus(String status) {
    selectedStatus.value = status;
    refreshData();
  }

  void search(String query) {
    searchQuery.value = query;
    refreshData();
  }

  Future<void> reviewApplication({
    required String appId,
    required String action, // approve, reject, request_info, revoke
    String reasonNote = '',
  }) async {
    try {
      isLoading.value = true;
      final success = await _service.reviewApplication(
        appId: appId,
        action: action,
        reasonNote: reasonNote,
      );

      if (success) {
        await refreshData();
        Get.back();
        final actionText = action == 'approve'
            ? 'Approved'
            : (action == 'reject'
                ? 'Rejected'
                : (action == 'revoke' ? 'Revoked' : 'Requested Information'));
        Get.snackbar(
          'Action Completed',
          'Application $appId has been $actionText.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to perform review action: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
