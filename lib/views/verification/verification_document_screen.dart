import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:momento/controllers/verification_controller.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/glass_container.dart';

class VerificationDocumentScreen extends StatelessWidget {
  const VerificationDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VerificationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Identity Verification',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2 of 3: Identity Document Upload',
              style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload Government ID or Registration',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your document is encrypted and accessible strictly to authorized Momento verification auditors. It will never be publicly displayed.',
              style: TextStyle(color: Colors.white60, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 20),

            const Text(
              'Document Type',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Obx(() {
              return GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedDocumentType.value,
                    dropdownColor: AppColors.surface,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: controller.documentTypes.map((docType) {
                      return DropdownMenuItem<String>(
                        value: docType,
                        child: Text(docType, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) controller.selectedDocumentType.value = val;
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            Obx(() {
              final file = controller.selectedDocumentFile.value;

              if (file != null) {
                return GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.file(
                          file,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.description_rounded, color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file.path.split('/').last,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => controller.pickDocument(ImageSource.gallery),
                              icon: const Icon(Icons.edit_rounded, color: AppColors.cyan, size: 20),
                              tooltip: 'Replace',
                            ),
                            IconButton(
                              onPressed: controller.removeDocument,
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GestureDetector(
                onTap: () => controller.pickDocument(ImageSource.gallery),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_rounded, color: AppColors.purple, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Tap to Select Document Image',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supports PNG, JPG, JPEG (Max 10MB)',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.selectedDocumentFile.value == null) {
                    Get.snackbar('Document Required', 'Please select or capture a valid document image.');
                    return;
                  }
                  Get.toNamed('/verification-summary');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next: Review & Submit',
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
}
