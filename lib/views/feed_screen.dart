import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('feed_screen.dart')),
      body: const Center(child: Text('feed_screen.dart Content')),
    );
  }
}
