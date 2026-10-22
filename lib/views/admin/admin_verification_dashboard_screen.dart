import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/admin_verification_controller.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/glass_container.dart';

class AdminVerificationDashboardScreen extends StatelessWidget {
  const AdminVerificationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminVerificationController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Momento Admin Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => controller.refreshData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.stats['total'] == 0) {
          return const Center(child: CircularProgressIndicator(color: AppColors.purple));
        }

        final stats = controller.stats;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verification & Oversight Dashboard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text(
                'Real-time metrics and application moderation stats',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('Total Applications', '${stats['total'] ?? 0}', Icons.folder_copy_rounded, AppColors.purple),
                  _buildStatCard('Pending Review', '${stats['pending'] ?? 0}', Icons.pending_actions_rounded, Colors.orangeAccent),
                  _buildStatCard('Under Review', '${stats['under_review'] ?? 0}', Icons.hourglass_bottom_rounded, AppColors.cyan),
                  _buildStatCard('Needs Info', '${stats['needs_info'] ?? 0}', Icons.help_outline_rounded, Colors.amberAccent),
                  _buildStatCard('Approved', '${stats['approved'] ?? 0}', Icons.verified_rounded, Colors.greenAccent),
                  _buildStatCard('Rejected / Revoked', '${(stats['rejected'] ?? 0) + (stats['revoked'] ?? 0)}', Icons.cancel_rounded, Colors.redAccent),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                'Quick Administrative Actions',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              _buildActionTile(
                title: 'Manage Verification Applications',
                subtitle: 'Review, approve, reject or request missing documents',
                icon: Icons.verified_user_rounded,
                color: AppColors.purple,
                onTap: () => Get.toNamed('/admin-verification-list'),
              ),
              const SizedBox(height: 12),

              _buildActionTile(
                title: 'User & Content Reports Moderation',
                subtitle: 'Investigate reported accounts, posts, reels, stories and comments',
                icon: Icons.flag_rounded,
                color: Colors.redAccent,
                onTap: () => Get.toNamed('/admin-report-list'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                count,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
