import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/admin_report_controller.dart';
import 'package:momento/models/report_model.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/glass_container.dart';

class AdminReportListScreen extends StatelessWidget {
  const AdminReportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminReportController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'User & Content Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() {
                return Row(
                  children: [
                    _buildFilterChip('All Status', 'all', controller),
                    _buildFilterChip('Open', 'open', controller),
                    _buildFilterChip('Under Review', 'under_review', controller),
                    _buildFilterChip('Resolved', 'resolved', controller),
                    _buildFilterChip('Dismissed', 'dismissed', controller),
                  ],
                );
              }),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.reports.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppColors.purple));
              }

              if (controller.reports.isEmpty) {
                return const Center(
                  child: Text(
                    'No reports found.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.reports.length,
                itemBuilder: (context, index) {
                  final report = controller.reports[index];
                  return _buildReportCard(context, report, controller);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, AdminReportController controller) {
    final isSelected = controller.selectedStatus.value == value;
    return GestureDetector(
      onTap: () => controller.filterStatus(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.redAccent : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, ReportModel report, AdminReportController controller) {
    Color statusColor = Colors.orangeAccent;
    if (report.status == 'resolved') statusColor = Colors.greenAccent;
    if (report.status == 'dismissed') statusColor = Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    report.targetType.toUpperCase(),
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reason: ${report.reason}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Target ID: ${report.targetId} ${report.targetTitle.isNotEmpty ? "(${report.targetTitle})" : ""}',
              style: const TextStyle(color: AppColors.cyan, fontSize: 12.5),
            ),
            if (report.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Details: ${report.details}',
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
            const Divider(color: Colors.white10, height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showActionDialog(context, report, 'resolve', controller);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Resolve', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showActionDialog(context, report, 'dismiss', controller);
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Dismiss', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showActionDialog(
    BuildContext context,
    ReportModel report,
    String action,
    AdminReportController controller,
  ) {
    final noteController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${action == 'resolve' ? 'Resolve' : 'Dismiss'} Report ${report.id}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: noteController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter moderation notes...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.reviewReport(
                reportId: report.id,
                action: action,
                adminNote: noteController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: action == 'resolve' ? Colors.green : Colors.grey),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
