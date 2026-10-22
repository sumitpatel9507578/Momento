import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/verification_controller.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/glass_container.dart';

class VerificationFormScreen extends StatelessWidget {
  const VerificationFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VerificationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Application Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1 of 3: Applicant Information',
              style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'Provide Official Verification Details',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),

            _buildTextField(
              controller: controller.legalNameController,
              label: 'Full Legal Name',
              hint: 'As displayed on official identification document',
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: controller.displayNameController,
              label: 'Public Display Name / Brand',
              hint: 'Name as shown on your Momento profile',
              icon: Icons.badge_rounded,
            ),
            const SizedBox(height: 16),

            const Text(
              'Account Category',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Obx(() {
              return GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedCategory.value,
                    dropdownColor: AppColors.surface,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: controller.categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) controller.selectedCategory.value = val;
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            _buildTextField(
              controller: controller.countryController,
              label: 'Country / Region',
              hint: 'e.g. United States, India, United Kingdom',
              icon: Icons.public_rounded,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: controller.reasonController,
              label: 'Reason for Request',
              hint: 'Explain why your account requires verification (public interest, creator, business, or anti-impersonation)',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: controller.websiteUrlController,
              label: 'Official Website / Social Links (Optional)',
              hint: 'https://example.com or news article link',
              icon: Icons.link_rounded,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.legalNameController.text.trim().isEmpty) {
                    Get.snackbar('Validation Error', 'Full legal name is required.');
                    return;
                  }
                  if (controller.reasonController.text.trim().length < 10) {
                    Get.snackbar('Validation Error', 'Please provide a reason for verification.');
                    return;
                  }
                  Get.toNamed('/verification-document');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next: Identity Document',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
