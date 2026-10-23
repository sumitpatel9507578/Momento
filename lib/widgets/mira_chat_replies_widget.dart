import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:momento/controllers/mira_ai_controller.dart';
import 'package:momento/models/message_model.dart';

class MiraChatRepliesWidget extends StatefulWidget {
  final List<MessageModel> messages;
  final TextEditingController inputController;
  final Function(String) onSend;

  const MiraChatRepliesWidget({
    super.key,
    required this.messages,
    required this.inputController,
    required this.onSend,
  });

  @override
  State<MiraChatRepliesWidget> createState() => _MiraChatRepliesWidgetState();
}

class _MiraChatRepliesWidgetState extends State<MiraChatRepliesWidget> {
  final MiraAiController _miraController = Get.put(MiraAiController());
  final RxList<String> _suggestions = <String>[].obs;
  final RxBool _isGenerating = false.obs;
  String _lastProcessedMessageId = '';

  @override
  void initState() {
    super.initState();
    _fetchRepliesIfNeeded();
  }

  @override
  void didUpdateWidget(covariant MiraChatRepliesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchRepliesIfNeeded();
  }

  void _fetchRepliesIfNeeded() {
    if (widget.messages.isEmpty) return;

    final lastMsg = widget.messages.last;
    if (lastMsg.id == _lastProcessedMessageId && _suggestions.isNotEmpty) {
      return;
    }

    _lastProcessedMessageId = lastMsg.id;
    _generateReplies();
  }

  Future<void> _generateReplies() async {
    if (widget.messages.isEmpty) return;

    _isGenerating.value = true;

    // Extract recent non-empty text messages (up to 5)
    final recentMsgs = widget.messages
        .where((m) => m.message.trim().isNotEmpty)
        .take(5)
        .map((m) => m.message)
        .toList();

    if (recentMsgs.isEmpty) {
      _isGenerating.value = false;
      return;
    }

    try {
      final replies = await _miraController.generateChatReplies(
        recentMessages: recentMsgs,
      );
      _suggestions.assignAll(replies);
    } catch (_) {
      // Fail gracefully
    } finally {
      _isGenerating.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_isGenerating.value) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 6),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.purpleAccent,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Mira AI generating smart replies...',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      if (_suggestions.isEmpty) return const SizedBox.shrink();

      return Container(
        height: 38,
        margin: const EdgeInsets.only(bottom: 6),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: _suggestions.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == _suggestions.length) {
              // Regenerate button
              return InkWell(
                onTap: _generateReplies,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.purpleAccent,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'More',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final suggestion = _suggestions[index];
            return InkWell(
              onTap: () {
                widget.inputController.text = suggestion;
                widget.inputController.selection = TextSelection.fromPosition(
                  TextPosition(offset: suggestion.length),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade900.withValues(alpha: 0.5),
                      Colors.deepPurple.shade800.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.purpleAccent,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      suggestion,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
