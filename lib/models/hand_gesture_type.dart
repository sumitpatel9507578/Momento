import 'package:flutter/material.dart';

enum HandGestureType {
  none,
  openPalm,
  victorySign,
  thumbsUp,
  closedFist,
  palmHeldSteady,
  swipeLeft,
  swipeRight,
  pointingUp,
}

extension HandGestureTypeExtension on HandGestureType {
  String get displayName {
    switch (this) {
      case HandGestureType.none:
        return 'No Gesture';
      case HandGestureType.openPalm:
        return 'Open Palm';
      case HandGestureType.victorySign:
        return 'Victory Sign (V)';
      case HandGestureType.thumbsUp:
        return 'Thumbs Up';
      case HandGestureType.closedFist:
        return 'Closed Fist';
      case HandGestureType.palmHeldSteady:
        return 'Palm Held Steady';
      case HandGestureType.swipeLeft:
        return 'Swipe Left';
      case HandGestureType.swipeRight:
        return 'Swipe Right';
      case HandGestureType.pointingUp:
        return 'Pointing Up';
    }
  }

  String get emoji {
    switch (this) {
      case HandGestureType.none:
        return '❓';
      case HandGestureType.openPalm:
        return '✋';
      case HandGestureType.victorySign:
        return '✌️';
      case HandGestureType.thumbsUp:
        return '👍';
      case HandGestureType.closedFist:
        return '✊';
      case HandGestureType.palmHeldSteady:
        return '🖐️';
      case HandGestureType.swipeLeft:
        return '👈';
      case HandGestureType.swipeRight:
        return '👉';
      case HandGestureType.pointingUp:
        return '☝️';
    }
  }

  IconData get iconData {
    switch (this) {
      case HandGestureType.none:
        return Icons.front_hand_outlined;
      case HandGestureType.openPalm:
        return Icons.pan_tool_rounded;
      case HandGestureType.victorySign:
        return Icons.two_wheeler_rounded;
      case HandGestureType.thumbsUp:
        return Icons.thumb_up_alt_rounded;
      case HandGestureType.closedFist:
        return Icons.sports_mma_rounded;
      case HandGestureType.palmHeldSteady:
        return Icons.back_hand_rounded;
      case HandGestureType.swipeLeft:
        return Icons.swipe_left_rounded;
      case HandGestureType.swipeRight:
        return Icons.swipe_right_rounded;
      case HandGestureType.pointingUp:
        return Icons.touch_app_rounded;
    }
  }

  String get defaultActionHint {
    switch (this) {
      case HandGestureType.none:
        return 'No action';
      case HandGestureType.openPalm:
        return 'Detect gesture & prepare';
      case HandGestureType.victorySign:
        return 'Capture Photo';
      case HandGestureType.thumbsUp:
        return 'Start Video Recording';
      case HandGestureType.closedFist:
        return 'Stop Video Recording';
      case HandGestureType.palmHeldSteady:
        return 'Activate Hands-free Countdown';
      case HandGestureType.swipeLeft:
        return 'Switch Camera Mode / Filter';
      case HandGestureType.swipeRight:
        return 'Switch Camera Mode / Filter';
      case HandGestureType.pointingUp:
        return 'Focus Camera';
    }
  }
}
