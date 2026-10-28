import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/splash_controller.dart';
import '../utils/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ScaleTransition(
          scale: controller.scaleAnimation,
          child: FadeTransition(
            opacity: controller.fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', height: 100, width: 100),

                SizedBox(height: size.height * 0.025),

                Text(
                  'Momento',
                  style: GoogleFonts.grandHotel(
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: size.height * 0.008),

                Text(
                  'Every Moment. Your Story.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.width * 0.033,
                    color: AppColors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
