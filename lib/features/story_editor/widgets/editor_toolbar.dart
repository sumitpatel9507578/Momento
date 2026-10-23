import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  final VoidCallback onText;
  final VoidCallback onStickers;
  final VoidCallback onMusic;
  final VoidCallback onRestyle;
  final VoidCallback onDraw;
  final VoidCallback onEffects;
  final VoidCallback onMention;
  final VoidCallback onSave;
  final VoidCallback onAiLabel;
  final VoidCallback onMore;
  final VoidCallback? onSubtitles;
  final bool isAiActive;

  const EditorToolbar({
    super.key,
    required this.onText,
    required this.onStickers,
    required this.onMusic,
    required this.onRestyle,
    required this.onDraw,
    required this.onEffects,
    required this.onMention,
    required this.onSave,
    required this.onAiLabel,
    required this.onMore,
    this.onSubtitles,
    required this.isAiActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolbarButton(Icons.text_format_rounded, 'Text', onText),
            _toolbarButton(
              Icons.sticky_note_2_outlined,
              'Stickers',
              onStickers,
            ),
            _toolbarButton(Icons.music_note_rounded, 'Music', onMusic),
            if (onSubtitles != null)
              _toolbarButton(Icons.subtitles_rounded, 'Subtitles', onSubtitles!),
            _toolbarButton(Icons.palette_outlined, 'Restyle', onRestyle),
            _toolbarButton(Icons.brush_rounded, 'Draw', onDraw),
            _toolbarButton(Icons.auto_fix_high_rounded, 'Effects', onEffects),
            _toolbarButton(Icons.alternate_email_rounded, 'Mention', onMention),
            _toolbarButton(Icons.download_rounded, 'Save', onSave),
            _toolbarButton(
              Icons.smart_toy_outlined,
              'AI Label',
              onAiLabel,
              isActive: isAiActive,
            ),
            _toolbarButton(Icons.more_horiz_rounded, 'More', onMore),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? Colors.purple : Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.white : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
