import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/admin_verification_controller.dart';
import 'package:momento/models/verification_application_model.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/glass_container.dart';

class AdminVerificationDetailScreen extends StatelessWidget {
  const AdminVerificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminVerificationController>();
    final VerificationApplicationModel app = Get.arguments as VerificationApplicationModel;
    final noteController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Application: ${app.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.purple,
                    child: Text(
                      app.userName.isNotEmpty ? app.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.displayName.isNotEmpty ? app.displayName : app.userName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '@${app.userHandle} • ${app.category}',
                          style: const TextStyle(color: AppColors.cyan, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: ${app.status.toUpperCase()}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Application Information',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _buildDetailRow('Full Legal Name', app.legalName),
                  const Divider(color: Colors.white10),
                  _buildDetailRow('Display Name', app.displayName),
                  const Divider(color: Colors.white10),
                  _buildDetailRow('Category', app.category),
                  const Divider(color: Colors.white10),
                  _buildDetailRow('Country / Region', app.country.isEmpty ? 'Not specified' : app.country),
                  const Divider(color: Colors.white10),
                  _buildDetailRow('Reason', app.reason),
                  const Divider(color: Colors.white10),
                  _buildDetailRow('Website / Link', app.websiteUrl.isEmpty ? 'None provided' : app.websiteUrl),
                  const Divider(color: Colors.white10),
                  _buildDetailRow('Document Type', app.documentType),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Uploaded Identity Document Evidence',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, color: AppColors.cyan, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${app.documentType} Attached',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          app.documentUrl.isNotEmpty ? app.documentUrl.split('/').last : 'Document verified on server',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Administrator Review Actions',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: noteController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Review note or reason for decision...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.reviewApplication(
                        appId: app.id,
                        action: 'approve',
                        reasonNote: noteController.text.trim().isEmpty ? 'Verified by Administrator' : noteController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.reviewApplication(
                        appId: app.id,
                        action: 'reject',
                        reasonNote: noteController.text.trim().isEmpty ? 'Does not meet eligibility' : noteController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.reviewApplication(
                        appId: app.id,
                        action: 'request_info',
                        reasonNote: noteController.text.trim().isEmpty ? 'Please update document image' : noteController.text.trim(),
                      );
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.amberAccent)),
                    child: const Text('Request Info', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.reviewApplication(
                        appId: app.id,
                        action: 'revoke',
                        reasonNote: noteController.text.trim().isEmpty ? 'Revoked by admin' : noteController.text.trim(),
                      );
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                    child: const Text('Revoke Badge', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
