import 'dart:math';

import 'package:hand_landmarker/hand_landmarker.dart';

import '../models/hand_gesture_type.dart';

class RecognitionResult {
  final HandGestureType gesture;
  final double confidence;
  final String details;

  const RecognitionResult({
    required this.gesture,
    required this.confidence,
    this.details = '',
  });

  static const RecognitionResult none = RecognitionResult(
    gesture: HandGestureType.none,
    confidence: 0.0,
    details: 'No hand or unclear gesture',
  );
}

class GestureRecognitionService {
  // Motion history for gesture tracking (steady palm, swipe)
  final List<Point<double>> _wristHistory = [];
  final List<DateTime> _timeHistory = [];
  static const int _historyLimit = 10;

  void resetHistory() {
    _wristHistory.clear();
    _timeHistory.clear();
  }

  RecognitionResult processHandLandmarks(Hand hand) {
    if (hand.landmarks.length < 21) {
      return RecognitionResult.none;
    }

    final landmarks = hand.landmarks;

    // Key points
    final wrist = Point(landmarks[0].x, landmarks[0].y);

    // Thumb
    final thumbMcp = Point(landmarks[2].x, landmarks[2].y);
    final thumbTip = Point(landmarks[4].x, landmarks[4].y);

    // Index
    final indexMcp = Point(landmarks[5].x, landmarks[5].y);
    final indexPip = Point(landmarks[6].x, landmarks[6].y);
    final indexTip = Point(landmarks[8].x, landmarks[8].y);

    // Middle
    final middleMcp = Point(landmarks[9].x, landmarks[9].y);
    final middleTip = Point(landmarks[12].x, landmarks[12].y);

    // Ring
    final ringMcp = Point(landmarks[13].x, landmarks[13].y);
    final ringTip = Point(landmarks[16].x, landmarks[16].y);

    // Pinky
    final pinkyMcp = Point(landmarks[17].x, landmarks[17].y);
    final pinkyTip = Point(landmarks[20].x, landmarks[20].y);

    // Record wrist position history for motion gestures
    final now = DateTime.now();
    _wristHistory.add(wrist);
    _timeHistory.add(now);
    if (_wristHistory.length > _historyLimit) {
      _wristHistory.removeAt(0);
      _timeHistory.removeAt(0);
    }

    // Distances from wrist
    final wristIndexMcpDist = _dist(wrist, indexMcp);
    if (wristIndexMcpDist < 0.01) {
      return RecognitionResult.none; // Invalid or collapsed landmarks
    }

    // Finger extension ratios (Tip-to-Wrist distance / MCP-to-Wrist distance)
    final indexRatio = _dist(wrist, indexTip) / wristIndexMcpDist;
    final middleRatio = _dist(wrist, middleTip) / _dist(wrist, middleMcp);
    final ringRatio = _dist(wrist, ringTip) / _dist(wrist, ringMcp);
    final pinkyRatio = _dist(wrist, pinkyTip) / _dist(wrist, pinkyMcp);

    // Thumb extension ratio
    final thumbRatio = _dist(wrist, thumbTip) / _dist(wrist, thumbMcp);

    // Extended flags
    final indexExtended = indexRatio > 1.25;
    final middleExtended = middleRatio > 1.25;
    final ringExtended = ringRatio > 1.25;
    final pinkyExtended = pinkyRatio > 1.25;

    // Curled flags
    final indexCurled = indexRatio < 1.12;
    final middleCurled = middleRatio < 1.12;
    final ringCurled = ringRatio < 1.12;
    final pinkyCurled = pinkyRatio < 1.12;

    // Hand scale reference (width of palm across MCPs)
    final palmWidth = _dist(indexMcp, pinkyMcp);

    // Check Swipe gesture first
    final swipeResult = _checkSwipeGesture();
    if (swipeResult != null) {
      return swipeResult;
    }

    // 1. Victory Sign / V Sign (Index & Middle extended, Ring & Pinky curled)
    if (indexExtended && middleExtended && ringCurled && pinkyCurled) {
      final vSeparation = _dist(indexTip, middleTip);
      if (vSeparation > palmWidth * 0.3) {
        final confidence = min(0.98, 0.7 + (vSeparation / (palmWidth * 2)));
        return RecognitionResult(
          gesture: HandGestureType.victorySign,
          confidence: confidence,
          details: 'Victory sign confirmed (Index & Middle extended)',
        );
      }
    }

    // 2. Thumbs Up (Thumb extended upwards, all 4 fingers curled)
    if (indexCurled && middleCurled && ringCurled && pinkyCurled) {
      final thumbPointingUp =
          thumbTip.y < thumbMcp.y && thumbTip.y < indexMcp.y;
      final thumbAwayFromPalm = _dist(thumbTip, indexMcp) > palmWidth * 0.7;

      if (thumbPointingUp && thumbAwayFromPalm && thumbRatio > 1.15) {
        final confidence = min(0.95, 0.75 + (thumbRatio - 1.15));
        return RecognitionResult(
          gesture: HandGestureType.thumbsUp,
          confidence: confidence,
          details: 'Thumbs up confirmed (Thumb extended up, fingers curled)',
        );
      }
    }

    // 3. Closed Fist (All 4 fingers curled + thumb curled/folded)
    if (indexCurled && middleCurled && ringCurled && pinkyCurled) {
      final thumbFolded = _dist(thumbTip, indexPip) < palmWidth * 1.2;
      if (thumbFolded) {
        return const RecognitionResult(
          gesture: HandGestureType.closedFist,
          confidence: 0.90,
          details: 'Closed fist confirmed (All fingers curled)',
        );
      }
    }

    // 4. Open Palm & Palm Held Steady
    if (indexExtended && middleExtended && ringExtended && pinkyExtended) {
      // Check if steady
      if (_isWristSteady()) {
        return const RecognitionResult(
          gesture: HandGestureType.palmHeldSteady,
          confidence: 0.92,
          details: 'Palm held steady in front of camera',
        );
      }

      final confidence = min(
        0.98,
        (indexRatio + middleRatio + ringRatio + pinkyRatio) / 8.0,
      );
      return RecognitionResult(
        gesture: HandGestureType.openPalm,
        confidence: confidence,
        details: 'Open palm confirmed (5 fingers extended)',
      );
    }

    // 5. Pointing Up (Only index extended)
    if (indexExtended && middleCurled && ringCurled && pinkyCurled) {
      return const RecognitionResult(
        gesture: HandGestureType.pointingUp,
        confidence: 0.85,
        details: 'Index finger pointing up',
      );
    }

    return RecognitionResult.none;
  }

  RecognitionResult? _checkSwipeGesture() {
    if (_wristHistory.length < 5) return null;

    final first = _wristHistory.first;
    final last = _wristHistory.last;
    final timeSpan = _timeHistory.last
        .difference(_timeHistory.first)
        .inMilliseconds;

    if (timeSpan < 150 || timeSpan > 800) return null;

    final dx = last.x - first.x;
    final dy = (last.y - first.y).abs();

    // Check if horizontal movement is strong and vertical movement is low
    if (dx.abs() > 0.22 && dy < 0.12) {
      if (dx > 0) {
        return const RecognitionResult(
          gesture: HandGestureType.swipeRight,
          confidence: 0.88,
          details: 'Horizontal swipe right detected',
        );
      } else {
        return const RecognitionResult(
          gesture: HandGestureType.swipeLeft,
          confidence: 0.88,
          details: 'Horizontal swipe left detected',
        );
      }
    }

    return null;
  }

  bool _isWristSteady() {
    if (_wristHistory.length < 6) return false;

    double totalMove = 0.0;
    for (int i = 1; i < _wristHistory.length; i++) {
      totalMove += _dist(_wristHistory[i - 1], _wristHistory[i]);
    }

    final avgMove = totalMove / (_wristHistory.length - 1);
    return avgMove < 0.012; // Very small movement
  }

  double _dist(Point<double> p1, Point<double> p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt(dx * dx + dy * dy);
  }
}
