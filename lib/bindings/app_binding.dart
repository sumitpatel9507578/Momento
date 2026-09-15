import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/comment_controller.dart';
import '../controllers/network_controller.dart';
import '../services/api_service.dart';
import '../services/comment_service.dart';
import '../services/music_service.dart';
import '../services/post_service.dart';
import '../services/reel_service.dart';
import '../services/story_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiService>(ApiService(), permanent: true);

    Get.lazyPut<PostService>(
      () => PostService(Get.find<ApiService>()),
      fenix: true,
    );
    Get.lazyPut<StoryService>(
      () => StoryService(Get.find<ApiService>()),
      fenix: true,
    );
    Get.lazyPut<ReelService>(
      () => ReelService(Get.find<ApiService>()),
      fenix: true,
    );
    Get.lazyPut<CommentService>(
      () => CommentService(Get.find<ApiService>()),
      fenix: true,
    );
    Get.lazyPut<MusicService>(
      () => MusicService(Get.find<ApiService>()),
      fenix: true,
    );

    Get.lazyPut<AuthController>(
      () => AuthController(apiService: Get.find<ApiService>()),
      fenix: true,
    );
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
    Get.lazyPut<NetworkController>(() => NetworkController(), fenix: true);
    Get.lazyPut<CommentController>(() => CommentController(), fenix: true);
  }
}
