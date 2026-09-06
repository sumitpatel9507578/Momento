import 'package:flutter/material.dart';

class MotionSettingsScreen extends StatelessWidget {
  const MotionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Motion Settings')),
      body: const Center(child: Text('Motion Settings Screen')),
    );
  }
}
