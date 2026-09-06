import 'package:get/get.dart';

import '../controllers/reel_controller.dart';
import '../services/pexels_service.dart';

class ReelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReelController>(
      () => ReelController(
        pexelsService: PexelsService(apiKey: 'YOUR_PEXELS_API_KEY'),
      ),
    );
  }
}
