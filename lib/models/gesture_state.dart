enum GestureState {
  disabled,
  initializing,
  ready,
  gestureDetected,
  confirming,
  capturingPhoto,
  recordingVideo,
  stoppingRecording,
  cooldown,
  error,
}

extension GestureStateExtension on GestureState {
  String get label {
    switch (this) {
      case GestureState.disabled:
        return 'Gesture Mode Disabled';
      case GestureState.initializing:
        return 'Initializing Camera & AI...';
      case GestureState.ready:
        return 'Ready for Gesture';
      case GestureState.gestureDetected:
        return 'Gesture Detected';
      case GestureState.confirming:
        return 'Confirming Gesture...';
      case GestureState.capturingPhoto:
        return 'Capturing Photo...';
      case GestureState.recordingVideo:
        return 'Recording Video...';
      case GestureState.stoppingRecording:
        return 'Stopping Video...';
      case GestureState.cooldown:
        return 'Cooldown Active';
      case GestureState.error:
        return 'Camera or Model Error';
    }
  }

  bool get isActiveRecording => this == GestureState.recordingVideo;
  bool get isProcessingMedia =>
      this == GestureState.capturingPhoto || this == GestureState.stoppingRecording;
}
