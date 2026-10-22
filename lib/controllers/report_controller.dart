import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/services/report_service.dart';

class ReportController extends GetxController {
  ReportService get _service => Get.find<ReportService>();

  final selectedReason = 'Spam or Scam'.obs;
  final detailsController = TextEditingController();
  final isLoading = false.obs;

  final List<String> reasons = [
    'Spam or Scam',
    'Impersonation or Fake Identity',
    'Harassment or Bullying',
    'Hate or Abusive Content',
    'Inappropriate Content',
    'Intellectual Property Concern',
    'Misinformation',
    'Other',
  ];

  Future<void> submitReport({
    required String targetId,
    required String targetType, // user, post, reel, comment, story
    String targetTitle = '',
  }) async {
    if (selectedReason.value.isEmpty) {
      Get.snackbar('Validation Error', 'Please select a reason for reporting.');
      return;
    }

    try {
      isLoading.value = true;
      final success = await _service.submitReport(
        targetId: targetId,
        targetType: targetType,
        reason: selectedReason.value,
        details: detailsController.text.trim(),
        targetTitle: targetTitle,
      );

      if (success) {
        detailsController.clear();
        Get.back();
        Get.snackbar(
          'Report Submitted',
          'Thank you. Your report has been submitted to Momento moderators.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar('Error', 'Failed to submit report. Please try again.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    detailsController.dispose();
    super.onClose();
  }
}
