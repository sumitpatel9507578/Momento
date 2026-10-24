import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  Function(MediaStream stream)? onLocalStream;
  Function(MediaStream stream)? onRemoteStream;
  Function(RTCIceCandidate candidate)? onIceCandidate;
  Function()? onConnectionClosed;

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };

  static const Map<String, dynamic> _configConstraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Future<void> initializeMediaStreams({bool isAudioOnly = false}) async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': isAudioOnly
          ? false
          : {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            },
    };

    try {
      localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      if (onLocalStream != null && localStream != null) {
        onLocalStream!(localStream!);
      }
    } catch (e) {
      debugPrint('WebRtcService getUserMedia error: $e');
    }
  }

  Future<void> createPeerConnectionInstance({bool isAudioOnly = false}) async {
    try {
      _peerConnection = await createPeerConnection(_iceServers, _configConstraints);

      _peerConnection!.onIceCandidate = (candidate) {
        if (onIceCandidate != null) {
          onIceCandidate!(candidate);
        }
      };

      _peerConnection!.onTrack = (event) {
        if (event.track.kind == 'video' || event.track.kind == 'audio') {
          if (event.streams.isNotEmpty) {
            remoteStream = event.streams[0];
            if (onRemoteStream != null) {
              onRemoteStream!(remoteStream!);
            }
          }
        }
      };

      if (localStream != null) {
        localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, localStream!);
        });
      }
    } catch (e) {
      debugPrint('WebRtcService createPeerConnection error: $e');
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer({
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    });
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final answer = await _peerConnection!.createAnswer({
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    });
    await _peerConnection!.setRemoteDescription(answer);
    return answer;
  }

  Future<void> setRemoteOffer(RTCSessionDescription offer) async {
    await _peerConnection?.setRemoteDescription(offer);
  }

  Future<void> setRemoteAnswer(RTCSessionDescription answer) async {
    await _peerConnection?.setRemoteDescription(answer);
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection?.addCandidate(candidate);
  }

  void toggleMute(bool isMuted) {
    if (localStream != null) {
      for (final track in localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }
  }

  void toggleVideo(bool isVideoEnabled) {
    if (localStream != null) {
      for (final track in localStream!.getVideoTracks()) {
        track.enabled = isVideoEnabled;
      }
    }
  }

  Future<void> switchCamera() async {
    if (localStream != null && localStream!.getVideoTracks().isNotEmpty) {
      final videoTrack = localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
    }
  }

  Future<void> dispose() async {
    try {
      await localStream?.dispose();
      await remoteStream?.dispose();
      await _peerConnection?.close();
      await _peerConnection?.dispose();
    } catch (e) {
      debugPrint('WebRtcService dispose error: $e');
    } finally {
      localStream = null;
      remoteStream = null;
      _peerConnection = null;
      if (onConnectionClosed != null) {
        onConnectionClosed!();
      }
    }
  }
}
