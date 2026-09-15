import 'package:get/get.dart';

import '../controllers/create_post_controller.dart';
import '../controllers/explore_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/reel_controller.dart';
import '../controllers/story_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<StoryController>(() => StoryController());
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<ProfileController>(() => ProfileController(), tag: 'me');
    Get.lazyPut<ReelController>(() => ReelController());
    Get.lazyPut<CreatePostController>(() => CreatePostController());
    Get.lazyPut<ExploreController>(() => ExploreController());
  }
}
