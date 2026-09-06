import 'package:flutter/material.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance Settings Screen')),
      body: const Center(child: Text('Appearance Settings Screen Content')),
    );
  }
}
