import 'package:get/get.dart';
import '../bindings/auth_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/music_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/reel_binding.dart';
import '../bindings/splash_binding.dart';
import '../views/chat_list_screen.dart';
import '../views/chat_screen.dart';
import '../views/create_post_screen.dart';
import '../views/edit_profile_screen.dart';
import '../views/followers_screen.dart';
import '../views/following_screen.dart';
import '../views/forgot_password_screen.dart';
import '../views/login_screen.dart';
import '../views/main_screen.dart';
import '../views/music_screen.dart';
import '../views/notifications_screen.dart';
import '../views/profile_screen.dart';
import '../views/reels_screen.dart';
import '../views/register_screen.dart';
import '../views/saved_posts_screen.dart';
import '../views/search_screen.dart';
import '../views/settings_screen.dart';
import '../views/splash_screen.dart';
import '../views/story_editor_screen.dart';
import '../views/story_viewer_screen.dart';
import '../views/post_details_screen.dart';
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
      page: () => const MainScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => ForgotPasswordScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
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
      name: AppRoutes.storyEditor,
      page: () => const StoryEditorScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.reels,
      page: () => const ReelsScreen(),
      binding: ReelBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.create,
      page: () => const CreatePostScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.saved,
      page: () => const SavedPostsScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.chatList,
      page: () => const ChatListScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/post-details',
      page: () => const PostDetailsScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.music,
      page: () => const MusicScreen(),
      binding: MusicBinding(),
    ),
    GetPage(
      name: AppRoutes.musicPicker,
      page: () => const MusicScreen(),
      binding: MusicBinding(),
    ),
  ];
}
