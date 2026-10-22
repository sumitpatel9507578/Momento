import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/admin_verification_controller.dart';
import 'package:momento/models/verification_application_model.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/glass_container.dart';

class AdminVerificationListScreen extends StatelessWidget {
  const AdminVerificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminVerificationController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Verification Queue',
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
                    _buildFilterChip('All', 'all', controller),
                    _buildFilterChip('Submitted', 'submitted', controller),
                    _buildFilterChip(
                      'Under Review',
                      'under_review',
                      controller,
                    ),
                    _buildFilterChip(
                      'Needs Info',
                      'additional_info_required',
                      controller,
                    ),
                    _buildFilterChip('Approved', 'approved', controller),
                    _buildFilterChip('Rejected', 'rejected', controller),
                  ],
                );
              }),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.applications.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.purple),
                );
              }

              if (controller.applications.isEmpty) {
                return const Center(
                  child: Text(
                    'No verification applications found.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.applications.length,
                itemBuilder: (context, index) {
                  final app = controller.applications[index];
                  return _buildApplicationCard(context, app);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    AdminVerificationController controller,
  ) {
    final isSelected = controller.selectedStatus.value == value;
    return GestureDetector(
      onTap: () => controller.filterByStatus(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.purple
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.purple : Colors.white10,
          ),
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

  Widget _buildApplicationCard(
    BuildContext context,
    VerificationApplicationModel app,
  ) {
    Color statusColor = Colors.orangeAccent;
    if (app.isApproved) statusColor = Colors.greenAccent;
    if (app.isRejected || app.isRevoked) statusColor = Colors.redAccent;
    if (app.isNeedsInfo) statusColor = Colors.amberAccent;

    return GestureDetector(
      onTap: () {
        Get.toNamed('/admin-verification-detail', arguments: app);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.purple.withValues(alpha: 0.3),
                    child: Text(
                      app.userName.isNotEmpty
                          ? app.userName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.displayName.isNotEmpty
                              ? app.displayName
                              : app.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        Text(
                          '@${app.userHandle.isNotEmpty ? app.userHandle : "applicant"} • ${app.category}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      app.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${app.id}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11.5,
                    ),
                  ),
                  Text(
                    'Submitted: ${app.submittedAt.day}/${app.submittedAt.month}/${app.submittedAt.year}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
