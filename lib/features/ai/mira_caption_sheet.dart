import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/mira_ai_controller.dart';

class MiraCaptionSheet extends StatefulWidget {
  final String initialPrompt;
  final String? imagePath;
  final Function(String caption, List<String> hashtags) onApply;

  const MiraCaptionSheet({
    super.key,
    this.initialPrompt = '',
    this.imagePath,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    String initialPrompt = '',
    String? imagePath,
    required Function(String caption, List<String> hashtags) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MiraCaptionSheet(
        initialPrompt: initialPrompt,
        imagePath: imagePath,
        onApply: onApply,
      ),
    );
  }

  @override
  State<MiraCaptionSheet> createState() => _MiraCaptionSheetState();
}

class _MiraCaptionSheetState extends State<MiraCaptionSheet> {
  late final TextEditingController _promptController;
  final MiraAiController _miraController = Get.put(MiraAiController());

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.initialPrompt);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generate() async {
    final prompt = _promptController.text.trim();
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      await _miraController.generateVisionCaption(widget.imagePath!);
    } else if (prompt.isNotEmpty) {
      await _miraController.generateCaptions(prompt);
    } else {
      Get.snackbar(
        'Prompt Empty',
        'Please enter a topic or upload an image for Mira AI.',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF181824),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Mira AI Caption Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Prompt Input
            TextField(
              controller: _promptController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: widget.imagePath != null
                    ? 'Image selected! Tap Generate for Mira Vision captions.'
                    : 'What is your post about? (e.g. Sunset in Goa with friends)',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF242436),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tone Selectors
            const Text(
              'Tone',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Wrap(
                spacing: 8,
                children: _miraController.availableTones.map((tone) {
                  final isSelected = _miraController.selectedTone.value == tone;
                  return ChoiceChip(
                    label: Text(tone),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8E2DE2),
                    backgroundColor: const Color(0xFF242436),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) _miraController.selectedTone.value = tone;
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Language Selectors
            const Text(
              'Language',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Wrap(
                spacing: 8,
                children: _miraController.availableLanguages.map((lang) {
                  final isSelected =
                      _miraController.selectedLanguage.value == lang;
                  return ChoiceChip(
                    label: Text(lang),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4A00E0),
                    backgroundColor: const Color(0xFF242436),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) _miraController.selectedLanguage.value = lang;
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Generate Button
            Obx(() {
              final isLoading =
                  _miraController.isLoadingCaptions.value ||
                  _miraController.isLoadingVision.value;
              return SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E2DE2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Generate Captions & Hashtags',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Results List
            Obx(() {
              if (_miraController.generatedCaptions.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  const Text(
                    'Generated Options (Tap to Select)',
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._miraController.generatedCaptions.map((caption) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242436),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.purpleAccent,
                          size: 14,
                        ),
                        onTap: () {
                          widget.onApply(
                            caption,
                            _miraController.generatedHashtags.toList(),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
