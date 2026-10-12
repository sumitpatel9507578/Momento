import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/explore_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/reel_controller.dart';
import '../controllers/story_controller.dart';
import '../services/api_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register ApiService if it is not already registered.
    if (!Get.isRegistered<ApiService>()) {
      Get.lazyPut<ApiService>(() => ApiService());
    }

    // Register AuthController with its required ApiService.
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(
        () => AuthController(apiService: Get.find<ApiService>()),
      );
    }

    // Register HomeController.
    Get.lazyPut<HomeController>(() => HomeController());

    // Register StoryController.
    Get.lazyPut<StoryController>(() => StoryController());

    // Register ProfileController.
    Get.lazyPut<ProfileController>(() => ProfileController());

    // Register the separate "me" ProfileController.
    Get.lazyPut<ProfileController>(() => ProfileController(), tag: 'me');

    // Register ReelController.
    Get.lazyPut<ReelController>(() => ReelController());

    // Register CreatePostController.
    Get.lazyPut<CreatePostController>(() => CreatePostController());

    // Register ExploreController.
    Get.lazyPut<ExploreController>(() => ExploreController());
  }
}
