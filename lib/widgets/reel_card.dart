import 'package:flutter/material.dart';

class ReelCard extends StatelessWidget {
  const ReelCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text('Reel Card', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
