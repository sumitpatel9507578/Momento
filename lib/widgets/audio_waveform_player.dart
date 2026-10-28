import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AudioWaveformPlayer extends StatefulWidget {
  final String audioUrl;
  final int? durationSeconds;
  final bool isMe;

  const AudioWaveformPlayer({
    super.key,
    required this.audioUrl,
    this.durationSeconds,
    this.isMe = false,
  });

  @override
  State<AudioWaveformPlayer> createState() => _AudioWaveformPlayerState();
}

class _AudioWaveformPlayerState extends State<AudioWaveformPlayer> {
  final AudioPlayer _player = AudioPlayer();
  final _isPlaying = false.obs;
  final _duration = Duration.zero.obs;
  final _position = Duration.zero.obs;

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      _duration.value = Duration(seconds: widget.durationSeconds!);
    }

    _player.onPlayerStateChanged.listen((state) {
      _isPlaying.value = state == PlayerState.playing;
    });

    _player.onDurationChanged.listen((d) {
      _duration.value = d;
    });

    _player.onPositionChanged.listen((p) {
      _position.value = p;
    });

    _player.onPlayerComplete.listen((_) {
      _isPlaying.value = false;
      _position.value = Duration.zero;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying.value) {
      await _player.pause();
    } else {
      if (widget.audioUrl.isNotEmpty) {
        if (widget.audioUrl.startsWith('http')) {
          await _player.play(UrlSource(widget.audioUrl));
        } else {
          await _player.play(DeviceFileSource(widget.audioUrl));
        }
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isMe ? Colors.white : Colors.purpleAccent;
    final secondaryColor = widget.isMe ? Colors.white70 : Colors.white54;

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Obx(() {
        final isPlaying = _isPlaying.value;
        final position = _position.value;
        final duration = _duration.value;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                size: 36,
                color: primaryColor,
              ),
              onPressed: _togglePlay,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Waveform Bars
                  SizedBox(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(16, (index) {
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;
                        final barRatio = (index + 1) / 16;
                        final isActive = barRatio <= progress;
                        final heights = [
                          12.0,
                          18.0,
                          8.0,
                          14.0,
                          20.0,
                          10.0,
                          16.0,
                          6.0,
                          18.0,
                          12.0,
                          20.0,
                          8.0,
                          14.0,
                          16.0,
                          10.0,
                          14.0,
                        ];
                        return Container(
                          width: 3,
                          height: heights[index % heights.length],
                          decoration: BoxDecoration(
                            color: isActive
                                ? primaryColor
                                : primaryColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPlaying
                        ? _formatDuration(position)
                        : _formatDuration(duration),
                    style: TextStyle(fontSize: 11, color: secondaryColor),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
