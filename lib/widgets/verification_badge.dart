import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;
  final EdgeInsetsGeometry padding;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.size = 16.0,
    this.padding = const EdgeInsets.only(left: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF2563EB), // Momento Verified Blue
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: size * 0.65,
          ),
        ),
      ),
    );
  }
}
