import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/verification_controller.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/glass_container.dart';

class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerificationController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Application Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => controller.loadEligibilityAndStatus(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.currentApplication.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          );
        }

        final app = controller.currentApplication.value;

        if (app == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.note_add_outlined,
                    color: Colors.white38,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Application Found',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You have not submitted a verification request yet.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.offNamed('/verification-info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Start Application'),
                  ),
                ],
              ),
            ),
          );
        }

        Color statusColor = Colors.orangeAccent;
        IconData statusIcon = Icons.hourglass_top_rounded;
        String statusTitle = 'Submitted & Under Review';
        String statusDesc =
            'Your verification application has been received and is currently queued for administrator review.';

        if (app.isApproved) {
          statusColor = Colors.greenAccent;
          statusIcon = Icons.verified_rounded;
          statusTitle = 'Verification Approved!';
          statusDesc =
              'Congratulations! Your account has been verified. The Blue Tick badge is active across your profile, posts, reels, and comments.';
        } else if (app.isNeedsInfo) {
          statusColor = Colors.amberAccent;
          statusIcon = Icons.help_outline_rounded;
          statusTitle = 'Additional Information Required';
          statusDesc =
              'The review team requested updated or additional document details to complete your review.';
        } else if (app.isRejected) {
          statusColor = Colors.redAccent;
          statusIcon = Icons.cancel_rounded;
          statusTitle = 'Application Not Approved';
          statusDesc =
              'Your verification request was reviewed and could not be approved at this time.';
        } else if (app.isRevoked) {
          statusColor = Colors.redAccent;
          statusIcon = Icons.no_accounts_rounded;
          statusTitle = 'Verification Badge Revoked';
          statusDesc =
              'Your verified status was revoked due to account policy or verification changes.';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor, width: 2),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusDesc,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: Colors.white10, height: 28),

                    _buildDetailRow('Application ID', app.id),
                    _buildDetailRow(
                      'Submitted Date',
                      '${app.submittedAt.day}/${app.submittedAt.month}/${app.submittedAt.year}',
                    ),
                    _buildDetailRow('Category', app.category),
                    _buildDetailRow('Status Code', app.status.toUpperCase()),

                    if (app.adminNote.isNotEmpty) ...[
                      const Divider(color: Colors.white10, height: 28),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Review Notes from Moderator:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          app.adminNote,
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              if (app.isNeedsInfo || app.isRejected)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Get.toNamed('/verification-resubmit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      app.isNeedsInfo
                          ? 'Provide Requested Information'
                          : 'Submit New Application',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12.5),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
