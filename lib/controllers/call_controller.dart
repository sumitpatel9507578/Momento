import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:momento/routes/app_routes.dart';
import 'package:momento/services/chat_socket_service.dart';
import 'package:momento/services/webrtc_service.dart';
import 'package:permission_handler/permission_handler.dart';

enum CallState { idle, outgoingRinging, incomingRinging, connected, ended }

class CallController extends GetxController {
  final WebRtcService _webrtcService = WebRtcService();
  final ChatSocketService _socketService = Get.find<ChatSocketService>();

  final callState = CallState.idle.obs;
  final isAudioOnly = false.obs;
  final isMuted = false.obs;
  final isVideoEnabled = true.obs;
  final callDurationSeconds = 0.obs;

  final peerUserId = ''.obs;
  final peerName = ''.obs;
  final peerAvatar = ''.obs;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  Timer? _durationTimer;
  Map<String, dynamic>? _incomingCallData;

  @override
  void onInit() {
    super.onInit();
    _setupSocketListeners();
  }

  Future<void> ensureRenderersInitialized() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      _webrtcService.onLocalStream = (stream) {
        localRenderer.srcObject = stream;
      };

      _webrtcService.onRemoteStream = (stream) {
        remoteRenderer.srcObject = stream;
      };

      _webrtcService.onIceCandidate = (candidate) {
        if (peerUserId.value.isNotEmpty) {
          _socketService.sendIceCandidate(peerUserId.value, candidate.toMap());
        }
      };
    } catch (e) {
      debugPrint('Error initializing call renderers: $e');
    }
  }

  void _setupSocketListeners() {
    _socketService.socket?.on('call:incoming', (data) {
      if (callState.value != CallState.idle) {
        _socketService.rejectCall(data['callerId']?.toString() ?? '');
        return;
      }

      _incomingCallData = Map<String, dynamic>.from(data as Map);
      peerUserId.value = (_incomingCallData!['callerId'] ?? '').toString();
      peerName.value = (_incomingCallData!['callerName'] ?? 'User').toString();
      peerAvatar.value = (_incomingCallData!['callerAvatar'] ?? '').toString();
      isAudioOnly.value = _incomingCallData!['isAudioOnly'] == true;

      callState.value = CallState.incomingRinging;
      Get.toNamed(AppRoutes.call);
    });

    _socketService.socket?.on('call:accepted', (data) async {
      if (callState.value == CallState.outgoingRinging) {
        callState.value = CallState.connected;
        _startDurationTimer();
        if (data is Map && data['answer'] != null) {
          final sdpMap = Map<String, dynamic>.from(data['answer'] as Map);
          final sdp = RTCSessionDescription(
            sdpMap['sdp']?.toString(),
            sdpMap['type']?.toString(),
          );
          await _webrtcService.setRemoteAnswer(sdp);
        }
      }
    });

    _socketService.socket?.on('call:ice_candidate', (data) async {
      if (data is Map && data['candidate'] != null) {
        final candidateMap = Map<String, dynamic>.from(
          data['candidate'] as Map,
        );
        final candidate = RTCIceCandidate(
          candidateMap['candidate']?.toString(),
          candidateMap['sdpMid']?.toString(),
          candidateMap['sdpMLineIndex'] as int?,
        );
        await _webrtcService.addIceCandidate(candidate);
      }
    });

    _socketService.socket?.on('call:ended', (_) {
      endCall(notifyRemote: false);
    });

    _socketService.socket?.on('call:rejected', (_) {
      endCall(notifyRemote: false);
      Get.snackbar('Call Rejected', '${peerName.value} declined the call.');
    });
  }

  Future<void> makeCall({
    required String targetUserId,
    required String targetName,
    required String targetAvatar,
    bool audioOnly = false,
  }) async {
    if (callState.value != CallState.idle) return;

    try {
      final micStatus = await Permission.microphone.request();
      if (!audioOnly) {
        await Permission.camera.request();
      }

      if (!micStatus.isGranted) {
        Get.snackbar(
          'Permission Required',
          'Microphone permission is needed to start a call.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    } catch (e) {
      debugPrint('Error requesting call permissions: $e');
    }

    peerUserId.value = targetUserId;
    peerName.value = targetName;
    peerAvatar.value = targetAvatar;
    isAudioOnly.value = audioOnly;
    isVideoEnabled.value = !audioOnly;
    isMuted.value = false;

    callState.value = CallState.outgoingRinging;
    Get.toNamed(AppRoutes.call);

    await ensureRenderersInitialized();
    await _webrtcService.initializeMediaStreams(isAudioOnly: audioOnly);
    await _webrtcService.createPeerConnectionInstance(isAudioOnly: audioOnly);

    final offer = await _webrtcService.createOffer();

    _socketService.initiateCall({
      'targetUserId': targetUserId,
      'isAudioOnly': audioOnly,
      'offer': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  Future<void> acceptCall() async {
    if (callState.value != CallState.incomingRinging ||
        _incomingCallData == null) {
      return;
    }

    try {
      final micStatus = await Permission.microphone.request();
      if (!isAudioOnly.value) {
        await Permission.camera.request();
      }

      if (!micStatus.isGranted) {
        Get.snackbar(
          'Permission Required',
          'Microphone permission is required to accept call.',
          snackPosition: SnackPosition.BOTTOM,
        );
        rejectCall();
        return;
      }
    } catch (e) {
      debugPrint('Error requesting call permissions: $e');
    }

    callState.value = CallState.connected;
    _startDurationTimer();

    await ensureRenderersInitialized();
    await _webrtcService.initializeMediaStreams(isAudioOnly: isAudioOnly.value);
    await _webrtcService.createPeerConnectionInstance(
      isAudioOnly: isAudioOnly.value,
    );

    final offerMap = Map<String, dynamic>.from(
      _incomingCallData!['offer'] as Map,
    );
    final offerSdp = RTCSessionDescription(
      offerMap['sdp']?.toString(),
      offerMap['type']?.toString(),
    );

    await _webrtcService.setRemoteOffer(offerSdp);
    final answer = await _webrtcService.createAnswer();

    _socketService.acceptCall(peerUserId.value, {
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  void rejectCall() {
    _socketService.rejectCall(peerUserId.value);
    endCall(notifyRemote: false);
  }

  void toggleMute() {
    isMuted.toggle();
    _webrtcService.toggleMute(isMuted.value);
  }

  void toggleVideo() {
    if (isAudioOnly.value) return;
    isVideoEnabled.toggle();
    _webrtcService.toggleVideo(isVideoEnabled.value);
  }

  Future<void> switchCamera() async {
    if (isAudioOnly.value) return;
    await _webrtcService.switchCamera();
  }

  void endCall({bool notifyRemote = true}) {
    if (notifyRemote && peerUserId.value.isNotEmpty) {
      _socketService.endCall(peerUserId.value);
    }

    _durationTimer?.cancel();
    callState.value = CallState.ended;
    _webrtcService.dispose();

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;

    Future.delayed(const Duration(milliseconds: 500), () {
      callState.value = CallState.idle;
      if (Get.currentRoute == AppRoutes.call) {
        Get.back();
      }
    });
  }

  void _startDurationTimer() {
    callDurationSeconds.value = 0;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDurationSeconds.value++;
    });
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _webrtcService.dispose();
    super.onClose();
  }
}
