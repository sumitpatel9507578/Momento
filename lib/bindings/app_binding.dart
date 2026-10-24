import 'package:get/get.dart';

import 'package:momento/controllers/auth_controller.dart';
import 'package:momento/controllers/call_controller.dart';
import 'package:momento/controllers/chat_controller.dart';
import 'package:momento/controllers/comment_controller.dart';
import 'package:momento/controllers/network_controller.dart';
import 'package:momento/controllers/note_controller.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/services/chat_socket_service.dart';
import 'package:momento/services/comment_service.dart';
import 'package:momento/services/music_service.dart';
import 'package:momento/services/note_service.dart';
import 'package:momento/services/post_service.dart';
import 'package:momento/services/reel_service.dart';
import 'package:momento/services/report_service.dart';
import 'package:momento/services/story_service.dart';
import 'package:momento/services/verification_service.dart';
import 'package:momento/services/webrtc_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<ChatSocketService>(
      ChatSocketService(apiService: Get.find<ApiService>()),
      permanent: true,
    );

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
    Get.lazyPut<VerificationService>(
      () => VerificationService(Get.find<ApiService>()),
      fenix: true,
    );
    Get.lazyPut<ReportService>(
      () => ReportService(Get.find<ApiService>()),
      fenix: true,
    );
    Get.lazyPut<NoteService>(
      () => NoteService(Get.find<ApiService>()),
      fenix: true,
    );
    Get.lazyPut<WebRtcService>(
      () => WebRtcService(),
      fenix: true,
    );

    Get.lazyPut<AuthController>(
      () => AuthController(apiService: Get.find<ApiService>()),
      fenix: true,
    );
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
    Get.lazyPut<NetworkController>(() => NetworkController(), fenix: true);
    Get.lazyPut<CommentController>(() => CommentController(), fenix: true);
    Get.lazyPut<NoteController>(() => NoteController(), fenix: true);
    Get.lazyPut<CallController>(() => CallController(), fenix: true);
  }
}
