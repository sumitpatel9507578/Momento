import 'package:get/get.dart';

import '../controllers/edit_profile_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // We use the userId from arguments as a tag to allow multiple
    // profile controller instances in the navigation stack.
    // If no argument is provided, it defaults to 'me' which is
    // registered in HomeBinding.
    final String? tag = Get.arguments?.toString();

    if (tag != null) {
      Get.lazyPut<ProfileController>(
        () => ProfileController(),
        tag: tag,
        fenix: true,
      );
    }

    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
}
