import 'package:get/get.dart';

import '../controllers/edit_profile_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/user_model.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    String? tag;
    final args = Get.arguments;
    if (args is String && args.isNotEmpty) {
      tag = args;
    } else if (args is UserModel && args.uid.isNotEmpty) {
      tag = args.uid;
    } else if (args is Map) {
      tag =
          (args['uid'] ??
                  args['id'] ??
                  args['_id'] ??
                  args['userId'] ??
                  args['user_id'])
              ?.toString();
    }

    if (tag != null && tag.isNotEmpty && tag != 'me') {
      Get.lazyPut<ProfileController>(
        () => ProfileController(),
        tag: tag,
        fenix: true,
      );
    } else {
      Get.lazyPut<ProfileController>(
        () => ProfileController(),
        tag: 'me',
        fenix: true,
      );
    }

    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
}
