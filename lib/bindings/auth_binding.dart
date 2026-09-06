import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/forgot_password_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/register_controller.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);

    Get.lazyPut<GoogleAuthService>(() => GoogleAuthService(), fenix: true);

    Get.lazyPut<AuthController>(
      () => AuthController(
        authService: Get.find<AuthService>(),
        googleAuthService: Get.find<GoogleAuthService>(),
      ),
    );

    Get.lazyPut<LoginController>(() => LoginController());

    Get.lazyPut<RegisterController>(() => RegisterController());

    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
  }
}
