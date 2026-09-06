import 'package:get/get.dart';

import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/reel_binding.dart';
import '../bindings/splash_binding.dart';
import '../views/edit_profile_screen.dart';
import '../views/followers_screen.dart';
import '../views/following_screen.dart';
import '../views/forgot_password_screen.dart';
import '../views/home_screen.dart';
import '../views/login_screen.dart';
import '../views/profile_screen.dart';
import '../views/reels_screen.dart';
import '../views/register_screen.dart';
import '../views/splash_screen.dart';
import '../views/story_viewer_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => ForgotPasswordScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => EditProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.followers,
      page: () => FollowersScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.following,
      page: () => FollowingScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.story,
      page: () => const StoryViewerScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.reels,
      page: () => ReelsScreen(),
      binding: ReelBinding(),
    ),
  ];
}
