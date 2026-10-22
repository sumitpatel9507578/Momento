import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/models/report_model.dart';
import 'package:momento/services/report_service.dart';

class AdminReportController extends GetxController {
  ReportService get _service => Get.find<ReportService>();

  final reports = <ReportModel>[].obs;
  final selectedStatus = 'all'.obs;
  final selectedTargetType = 'all'.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      isLoading.value = true;
      final list = await _service.fetchAdminReports(
        status: selectedStatus.value,
        targetType: selectedTargetType.value,
      );
      reports.assignAll(list);
    } catch (e) {
      debugPrint("AdminReportController error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void filterStatus(String status) {
    selectedStatus.value = status;
    loadReports();
  }

  void filterTarget(String targetType) {
    selectedTargetType.value = targetType;
    loadReports();
  }

  Future<void> reviewReport({
    required String reportId,
    required String action, // resolve, dismiss, review
    String adminNote = '',
  }) async {
    try {
      isLoading.value = true;
      final success = await _service.reviewReport(
        reportId: reportId,
        action: action,
        adminNote: adminNote,
      );

      if (success) {
        await loadReports();
        Get.back();
        Get.snackbar(
          'Report Updated',
          'Report $reportId action ($action) processed successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update report: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
