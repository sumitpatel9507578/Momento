import 'package:get/get.dart';

import '../controllers/reel_controller.dart';

class ReelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReelController>(() => ReelController());
  }
}
