import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../controllers/reel_controller.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';

class ReelsScreen extends StatelessWidget {
  ReelsScreen({super.key});

  final ReelController controller = Get.find<ReelController>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,

      body: Obx(() {
        if (controller.isLoading.value && controller.reels.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: controller.reels.length,
          onPageChanged: (index) {
            controller.playVideo(index);

            if (index >= controller.reels.length - 3) {
              controller.loadMore();
            }
          },
          itemBuilder: (context, index) {
            final reel = controller.reels[index];
            final videoController = controller.getVideoController(index);

            return Stack(
              fit: StackFit.expand,
              children: [
                if (videoController != null &&
                    videoController.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoController.value.size.width,
                      height: videoController.value.size.height,
                      child: VideoPlayer(videoController),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                Positioned(
                  left: size.width * 0.04,
                  right: size.width * 0.22,
                  bottom: size.height * 0.05,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${reel.creatorName}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        'Popular video on Pexels',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: size.width * 0.04,
                  bottom: size.height * 0.12,
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: size.width * 0.075,
                      ),

                      SizedBox(height: size.height * 0.025),

                      Icon(
                        Icons.comment_outlined,
                        color: Colors.white,
                        size: size.width * 0.075,
                      ),

                      SizedBox(height: size.height * 0.025),

                      Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                        size: size.width * 0.075,
                      ),

                      SizedBox(height: size.height * 0.025),

                      Icon(
                        Icons.bookmark_border,
                        color: Colors.white,
                        size: size.width * 0.075,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }),

      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(
          size.width * 0.03,
          0,
          size.width * 0.03,
          size.height * 0.015,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  Get.offAllNamed(AppRoutes.home);
                },
                icon: Icon(
                  Icons.home_rounded,
                  color: Colors.white70,
                  size: size.width * 0.07,
                ),
              ),
              IconButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.search);
                },
                icon: Icon(
                  Icons.explore_outlined,
                  color: Colors.white70,
                  size: size.width * 0.07,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: size.width * 0.13,
                  height: size.width * 0.13,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: size.width * 0.075,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.reels);
                },
                icon: Icon(
                  Icons.play_circle_fill_rounded,
                  color: AppColors.purple,
                  size: size.width * 0.07,
                ),
              ),
              IconButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.profile);
                },
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white70,
                  size: size.width * 0.07,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
