import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/forgot_password_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/register_controller.dart';
import '../services/api_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(apiService: Get.find<ApiService>()),
    );

    Get.lazyPut<LoginController>(() => LoginController());

    Get.lazyPut<RegisterController>(() => RegisterController());

    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
  }
}
