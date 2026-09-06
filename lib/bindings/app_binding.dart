import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/network_controller.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService());
    Get.lazyPut<GoogleAuthService>(() => GoogleAuthService());

    Get.lazyPut<AuthController>(
      () => AuthController(
        authService: Get.find<AuthService>(),
        googleAuthService: Get.find<GoogleAuthService>(),
      ),
    );
    Get.lazyPut<NetworkController>(() => NetworkController(), fenix: true);
  }
}
