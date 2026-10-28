import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:momento/controllers/call_controller.dart';
import 'package:momento/utils/api_constants.dart';
import 'package:momento/utils/app_colors.dart';

class CallScreen extends GetView<CallController> {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          final state = controller.callState.value;
          final isAudioOnly = controller.isAudioOnly.value;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Remote Video Background (For Video Call)
              if (!isAudioOnly && state == CallState.connected)
                RTCVideoView(
                  controller.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              else
                // Dark Gradient & Avatar Background for Audio Call / Connecting
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E1035), Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        final avatarProvider = ApiConstants.getImageProvider(
                          controller.peerAvatar.value,
                        );
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: AppColors.purple.withValues(
                                alpha: 0.3,
                              ),
                              backgroundImage: avatarProvider,
                              child: avatarProvider == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 54,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              controller.peerName.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getStatusText(
                                state,
                                controller.callDurationSeconds.value,
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

              // 2. Picture-In-Picture Local Video Preview (Top Right)
              if (!isAudioOnly &&
                  controller.isVideoEnabled.value &&
                  (state == CallState.connected ||
                      state == CallState.outgoingRinging))
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 110,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        border: Border.all(color: Colors.white24, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: RTCVideoView(
                        controller.localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),

              // 3. Top Call Type Indicator & Back Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Get.back(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isAudioOnly ? 'Momento Audio Call' : 'Momento Video Call',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Bottom Controls / Incoming Call Action Bar
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 30,
                left: 20,
                right: 20,
                child: state == CallState.incomingRinging
                    ? _buildIncomingCallBar()
                    : _buildActiveCallBar(),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildIncomingCallBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Reject Call Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: controller.rejectCall,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Decline',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),

          // Accept Call Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: controller.acceptCall,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Accept',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle Mute
          Obx(
            () => CircleAvatar(
              radius: 24,
              backgroundColor: controller.isMuted.value
                  ? Colors.white24
                  : Colors.grey[850],
              child: IconButton(
                icon: Icon(
                  controller.isMuted.value
                      ? Icons.mic_off_rounded
                      : Icons.mic_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: controller.toggleMute,
              ),
            ),
          ),

          // Camera Flip
          if (!controller.isAudioOnly.value)
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[850],
              child: IconButton(
                icon: const Icon(
                  Icons.flip_camera_ios_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: controller.switchCamera,
              ),
            ),

          // Toggle Video
          if (!controller.isAudioOnly.value)
            Obx(
              () => CircleAvatar(
                radius: 24,
                backgroundColor: !controller.isVideoEnabled.value
                    ? Colors.white24
                    : Colors.grey[850],
                child: IconButton(
                  icon: Icon(
                    controller.isVideoEnabled.value
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: controller.toggleVideo,
                ),
              ),
            ),

          // End Call Button
          GestureDetector(
            onTap: controller.endCall,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(CallState state, int seconds) {
    switch (state) {
      case CallState.outgoingRinging:
        return 'Calling...';
      case CallState.incomingRinging:
        return 'Incoming call...';
      case CallState.connected:
        final mins = (seconds ~/ 60).toString().padLeft(2, '0');
        final secs = (seconds % 60).toString().padLeft(2, '0');
        return '$mins:$secs';
      case CallState.ended:
        return 'Call ended';
      default:
        return 'Connecting...';
    }
  }
}
