import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../../models/hand_gesture_type.dart';

class HandLandmarkPainter extends CustomPainter {
  final List<Hand> hands;
  final HandGestureType currentGesture;
  final double confidence;
  final bool isFrontCamera;

  HandLandmarkPainter({
    required this.hands,
    required this.currentGesture,
    required this.confidence,
    required this.isFrontCamera,
  });

  static const List<List<int>> _connections = [
    // Thumb
    [0, 1], [1, 2], [2, 3], [3, 4],
    // Index finger
    [0, 5], [5, 6], [6, 7], [7, 8],
    // Middle finger
    [9, 10], [10, 11], [11, 12],
    // Ring finger
    [13, 14], [14, 15], [15, 16],
    // Pinky finger
    [0, 17], [17, 18], [18, 19], [19, 20],
    // Palm connections
    [5, 9], [9, 13], [13, 17],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty) return;

    final linePaint = Paint()
      ..color = _getGestureColor(currentGesture)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final landmarkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final tipPaint = Paint()
      ..color = _getGestureColor(currentGesture)
      ..style = PaintingStyle.fill;

    const tipIndices = {4, 8, 12, 16, 20};

    for (final hand in hands) {
      final landmarks = hand.landmarks;
      if (landmarks.isEmpty) continue;

      final points = landmarks.map((lm) {
        final double x = isFrontCamera
            ? (1.0 - lm.x) * size.width
            : lm.x * size.width;
        final double y = lm.y * size.height;
        return Offset(x, y);
      }).toList();

      for (final conn in _connections) {
        final startIdx = conn[0];
        final endIdx = conn[1];
        if (startIdx < points.length && endIdx < points.length) {
          canvas.drawLine(points[startIdx], points[endIdx], linePaint);
        }
      }

      for (int i = 0; i < points.length; i++) {
        final isTip = tipIndices.contains(i);
        final radius = isTip ? 6.0 : 4.0;
        final paint = isTip ? tipPaint : landmarkPaint;
        canvas.drawCircle(points[i], radius, paint);
      }
    }
  }

  Color _getGestureColor(HandGestureType gesture) {
    switch (gesture) {
      case HandGestureType.openPalm:
      case HandGestureType.palmHeldSteady:
        return const Color(0xFF00FF88);
      case HandGestureType.victorySign:
        return const Color(0xFF00E5FF);
      case HandGestureType.thumbsUp:
        return const Color(0xFFFFD700);
      case HandGestureType.closedFist:
        return const Color(0xFFFF3366);
      case HandGestureType.pointingUp:
        return const Color(0xFFAB47BC);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  @override
  bool shouldRepaint(covariant HandLandmarkPainter oldDelegate) {
    return oldDelegate.hands != hands ||
        oldDelegate.currentGesture != currentGesture ||
        oldDelegate.confidence != confidence ||
        oldDelegate.isFrontCamera != isFrontCamera;
  }
}
