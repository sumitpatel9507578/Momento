import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../utils/app_colors.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: 10,
        ),
        child: Column(
          children: [
            _buildSection(
              title: 'Account',
              items: [
                _buildSettingItem(
                  Icons.person_outline_rounded,
                  'Personal Information',
                ),
                _buildSettingItem(
                  Icons.lock_outline_rounded,
                  'Password & Security',
                ),
                _buildSettingItem(Icons.verified_user_outlined, 'Verification'),
              ],
            ),
            _buildSection(
              title: 'Activity',
              items: [
                _buildSettingItem(
                  Icons.favorite_border_rounded,
                  'Interactions',
                ),
                _buildSettingItem(Icons.history_rounded, 'Recent History'),
                _buildSettingItem(Icons.archive_outlined, 'Archive'),
              ],
            ),
            _buildSection(
              title: 'Preferences',
              items: [
                _buildSettingItem(
                  Icons.notifications_none_rounded,
                  'Notifications',
                ),
                _buildSettingItem(Icons.privacy_tip_outlined, 'Privacy'),
                _buildSettingItem(Icons.language_rounded, 'Language'),
                _buildSettingItem(Icons.dark_mode_outlined, 'Appearance'),
              ],
            ),
            _buildSection(
              title: 'Support',
              items: [
                _buildSettingItem(Icons.help_outline_rounded, 'Help Center'),
                _buildSettingItem(Icons.info_outline_rounded, 'About Momento'),
              ],
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                Get.dialog(
                  AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Get.back();
                          await authController.logout();
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(16),
                child: const Center(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Momento v1.0.0',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white24,
        size: 14,
      ),
      onTap: () {},
    );
  }
}
