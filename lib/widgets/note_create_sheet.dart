import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/note_controller.dart';
import 'package:momento/models/note_model.dart';
import 'package:momento/utils/app_colors.dart';
import 'package:momento/widgets/user_avatar.dart';

class NoteCreateSheet extends StatefulWidget {
  final NoteModel? currentNote;
  final String? profileImage;

  const NoteCreateSheet({super.key, this.currentNote, this.profileImage});

  static Future<void> show(
    BuildContext context, {
    NoteModel? currentNote,
    String? profileImage,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          NoteCreateSheet(currentNote: currentNote, profileImage: profileImage),
    );
  }

  @override
  State<NoteCreateSheet> createState() => _NoteCreateSheetState();
}

class _NoteCreateSheetState extends State<NoteCreateSheet> {
  final TextEditingController _textController = TextEditingController();
  final NoteController _noteController = Get.find<NoteController>();
  final _isPosting = false.obs;

  @override
  void initState() {
    super.initState();
    if (widget.currentNote != null) {
      _textController.text = widget.currentNote!.noteText;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handlePost() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _isPosting.value = true;

    final success = await _noteController.createNote(text);
    _isPosting.value = false;
    if (mounted && success) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.currentNote == null) return;

    _isPosting.value = true;

    final success = await _noteController.deleteNote(widget.currentNote!.id);
    _isPosting.value = false;
    if (mounted && success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const Text(
                  'New Note',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isPosting.value ? null : _handlePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isPosting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Share',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            UserAvatar(
              imageUrl:
                  widget.profileImage ?? widget.currentNote?.profileImage ?? '',
              size: 70,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLength: 60,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Share a thought...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
            if (widget.currentNote != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _isPosting.value ? null : _handleDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text(
                  'Delete Note',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
