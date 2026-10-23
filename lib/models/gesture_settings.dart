import 'dart:convert';
import 'package:camera/camera.dart';
import 'hand_gesture_type.dart';

class GestureSettings {
  final bool isGestureModeEnabled;
  final HandGestureType photoGesture;
  final HandGestureType startVideoGesture;
  final HandGestureType stopVideoGesture;
  final HandGestureType switchModeGesture;
  final bool enablePhotoCapture;
  final bool enableVideoStart;
  final bool enableVideoStop;
  final bool enableModeSwitch;
  final int countdownSeconds;
  final int confirmationMs;
  final double confidenceThreshold;
  final int cooldownSeconds;
  final CameraLensDirection cameraLens;
  final bool showLandmarks;
  final bool enableSoundFeedback;

  const GestureSettings({
    this.isGestureModeEnabled = true,
    this.photoGesture = HandGestureType.victorySign,
    this.startVideoGesture = HandGestureType.thumbsUp,
    this.stopVideoGesture = HandGestureType.closedFist,
    this.switchModeGesture = HandGestureType.swipeRight,
    this.enablePhotoCapture = true,
    this.enableVideoStart = true,
    this.enableVideoStop = true,
    this.enableModeSwitch = true,
    this.countdownSeconds = 3,
    this.confirmationMs = 600,
    this.confidenceThreshold = 0.65,
    this.cooldownSeconds = 2,
    this.cameraLens = CameraLensDirection.front,
    this.showLandmarks = true,
    this.enableSoundFeedback = true,
  });

  GestureSettings copyWith({
    bool? isGestureModeEnabled,
    HandGestureType? photoGesture,
    HandGestureType? startVideoGesture,
    HandGestureType? stopVideoGesture,
    HandGestureType? switchModeGesture,
    bool? enablePhotoCapture,
    bool? enableVideoStart,
    bool? enableVideoStop,
    bool? enableModeSwitch,
    int? countdownSeconds,
    int? confirmationMs,
    double? confidenceThreshold,
    int? cooldownSeconds,
    CameraLensDirection? cameraLens,
    bool? showLandmarks,
    bool? enableSoundFeedback,
  }) {
    return GestureSettings(
      isGestureModeEnabled: isGestureModeEnabled ?? this.isGestureModeEnabled,
      photoGesture: photoGesture ?? this.photoGesture,
      startVideoGesture: startVideoGesture ?? this.startVideoGesture,
      stopVideoGesture: stopVideoGesture ?? this.stopVideoGesture,
      switchModeGesture: switchModeGesture ?? this.switchModeGesture,
      enablePhotoCapture: enablePhotoCapture ?? this.enablePhotoCapture,
      enableVideoStart: enableVideoStart ?? this.enableVideoStart,
      enableVideoStop: enableVideoStop ?? this.enableVideoStop,
      enableModeSwitch: enableModeSwitch ?? this.enableModeSwitch,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      confirmationMs: confirmationMs ?? this.confirmationMs,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      cameraLens: cameraLens ?? this.cameraLens,
      showLandmarks: showLandmarks ?? this.showLandmarks,
      enableSoundFeedback: enableSoundFeedback ?? this.enableSoundFeedback,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isGestureModeEnabled': isGestureModeEnabled,
      'photoGesture': photoGesture.name,
      'startVideoGesture': startVideoGesture.name,
      'stopVideoGesture': stopVideoGesture.name,
      'switchModeGesture': switchModeGesture.name,
      'enablePhotoCapture': enablePhotoCapture,
      'enableVideoStart': enableVideoStart,
      'enableVideoStop': enableVideoStop,
      'enableModeSwitch': enableModeSwitch,
      'countdownSeconds': countdownSeconds,
      'confirmationMs': confirmationMs,
      'confidenceThreshold': confidenceThreshold,
      'cooldownSeconds': cooldownSeconds,
      'cameraLens': cameraLens.name,
      'showLandmarks': showLandmarks,
      'enableSoundFeedback': enableSoundFeedback,
    };
  }

  factory GestureSettings.fromMap(Map<String, dynamic> map) {
    return GestureSettings(
      isGestureModeEnabled: map['isGestureModeEnabled'] as bool? ?? true,
      photoGesture: _parseGesture(map['photoGesture'], HandGestureType.victorySign),
      startVideoGesture: _parseGesture(map['startVideoGesture'], HandGestureType.thumbsUp),
      stopVideoGesture: _parseGesture(map['stopVideoGesture'], HandGestureType.closedFist),
      switchModeGesture: _parseGesture(map['switchModeGesture'], HandGestureType.swipeRight),
      enablePhotoCapture: map['enablePhotoCapture'] as bool? ?? true,
      enableVideoStart: map['enableVideoStart'] as bool? ?? true,
      enableVideoStop: map['enableVideoStop'] as bool? ?? true,
      enableModeSwitch: map['enableModeSwitch'] as bool? ?? true,
      countdownSeconds: map['countdownSeconds'] as int? ?? 3,
      confirmationMs: map['confirmationMs'] as int? ?? 600,
      confidenceThreshold: (map['confidenceThreshold'] as num?)?.toDouble() ?? 0.65,
      cooldownSeconds: map['cooldownSeconds'] as int? ?? 2,
      cameraLens: map['cameraLens'] == 'back' ? CameraLensDirection.back : CameraLensDirection.front,
      showLandmarks: map['showLandmarks'] as bool? ?? true,
      enableSoundFeedback: map['enableSoundFeedback'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GestureSettings.fromJson(String source) =>
      GestureSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);

  static HandGestureType _parseGesture(dynamic val, HandGestureType fallback) {
    if (val == null || val is! String) return fallback;
    return HandGestureType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => fallback,
    );
  }
}
