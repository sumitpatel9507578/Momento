import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/verification_controller.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/glass_container.dart';

class VerificationSummaryScreen extends StatelessWidget {
  const VerificationSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VerificationController>();
    final isConfirmed = false.obs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Review Application',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 3 of 3: Final Review',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Confirm Your Application Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),

            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _buildSummaryItem(
                    'Full Legal Name',
                    controller.legalNameController.text,
                  ),
                  const Divider(color: Colors.white10),
                  _buildSummaryItem(
                    'Public Display Name',
                    controller.displayNameController.text,
                  ),
                  const Divider(color: Colors.white10),
                  _buildSummaryItem(
                    'Category',
                    controller.selectedCategory.value,
                  ),
                  const Divider(color: Colors.white10),
                  _buildSummaryItem(
                    'Country / Region',
                    controller.countryController.text.isEmpty
                        ? 'Not specified'
                        : controller.countryController.text,
                  ),
                  const Divider(color: Colors.white10),
                  _buildSummaryItem('Reason', controller.reasonController.text),
                  const Divider(color: Colors.white10),
                  _buildSummaryItem(
                    'Document Type',
                    controller.selectedDocumentType.value,
                  ),
                  const Divider(color: Colors.white10),
                  _buildSummaryItem(
                    'Document Attached',
                    controller.selectedDocumentFile.value != null
                        ? 'Yes (${controller.selectedDocumentFile.value!.path.split('/').last})'
                        : 'No',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Obx(() {
              return GestureDetector(
                onTap: () => isConfirmed.value = !isConfirmed.value,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isConfirmed.value,
                      onChanged: (val) => isConfirmed.value = val == true,
                      activeColor: AppColors.purple,
                      checkColor: Colors.white,
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'I certify that all information and identity documents provided are genuine, accurate, and belong to me.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            Obx(() {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (!isConfirmed.value || controller.isLoading.value)
                      ? null
                      : () => controller.submitApplication(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Verification Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
