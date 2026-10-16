import 'package:flutter/material.dart';

enum LayerType { text, sticker, draw, mention }

class EditorLayer {
  final String id;
  final LayerType type;
  final String content;
  Offset position;
  double scale;
  double rotation;
  Color color;
  double fontSize;
  String? fontFamily;
  bool hasBackground;
  TextAlign textAlign;

  EditorLayer({
    required this.id,
    required this.type,
    required this.content,
    this.position = const Offset(150, 300),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = Colors.white,
    this.fontSize = 24.0,
    this.fontFamily,
    this.hasBackground = false,
    this.textAlign = TextAlign.center,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'x': position.dx,
        'y': position.dy,
        'scale': scale,
        'rotation': rotation,
        'color': color.value,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'hasBackground': hasBackground,
        'textAlign': textAlign.index,
      };

  factory EditorLayer.fromJson(Map<String, dynamic> json) => EditorLayer(
        id: json['id'] ?? '',
        type: LayerType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => LayerType.text,
        ),
        content: json['content'] ?? '',
        position: Offset(json['x'] ?? 150.0, json['y'] ?? 300.0),
        scale: json['scale'] ?? 1.0,
        rotation: json['rotation'] ?? 0.0,
        color: Color(json['color'] ?? Colors.white.value),
        fontSize: json['fontSize'] ?? 24.0,
        fontFamily: json['fontFamily'],
        hasBackground: json['hasBackground'] ?? false,
        textAlign: TextAlign.values[json['textAlign'] ?? 0],
      );
}
