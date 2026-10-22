import 'package:get/get.dart';
import 'package:momento/bindings/auth_binding.dart';
import 'package:momento/bindings/home_binding.dart';
import 'package:momento/bindings/music_binding.dart';
import 'package:momento/bindings/profile_binding.dart';
import 'package:momento/bindings/reel_binding.dart';
import 'package:momento/bindings/splash_binding.dart';
import 'package:momento/features/ar_camera/ar_camera_screen.dart';
import 'package:momento/features/ar_camera/ar_media_preview_screen.dart';
import 'package:momento/features/story_editor/story_editor_screen.dart';
import 'package:momento/routes/app_routes.dart';
import 'package:momento/views/admin/admin_report_list_screen.dart';
import 'package:momento/views/admin/admin_verification_dashboard_screen.dart';
import 'package:momento/views/admin/admin_verification_detail_screen.dart';
import 'package:momento/views/admin/admin_verification_list_screen.dart';
import 'package:momento/views/chat_list_screen.dart';
import 'package:momento/views/chat_screen.dart';
import 'package:momento/views/complete_profile_screen.dart';
import 'package:momento/views/create_post_screen.dart';
import 'package:momento/views/edit_profile_screen.dart';
import 'package:momento/views/find_people_screen.dart';
import 'package:momento/views/followers_screen.dart';
import 'package:momento/views/following_screen.dart';
import 'package:momento/views/forgot_password_screen.dart';
import 'package:momento/views/login_screen.dart';
import 'package:momento/views/logout_loading_screen.dart';
import 'package:momento/views/main_screen.dart';
import 'package:momento/views/music_screen.dart';
import 'package:momento/views/notifications_screen.dart';
import 'package:momento/views/post_details_screen.dart';
import 'package:momento/views/profile_screen.dart';
import 'package:momento/views/reels_screen.dart';
import 'package:momento/views/register_screen.dart';
import 'package:momento/views/saved_posts_screen.dart';
import 'package:momento/views/search_screen.dart';
import 'package:momento/views/settings_screen.dart';
import 'package:momento/views/splash_screen.dart';
import 'package:momento/views/story_viewer_screen.dart';
import 'package:momento/views/verification/verification_document_screen.dart';
import 'package:momento/views/verification/verification_eligibility_screen.dart';
import 'package:momento/views/verification/verification_form_screen.dart';
import 'package:momento/views/verification/verification_info_screen.dart';
import 'package:momento/views/verification/verification_resubmit_screen.dart';
import 'package:momento/views/verification/verification_status_screen.dart';
import 'package:momento/views/verification/verification_summary_screen.dart';


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
    GetPage(
      name: AppRoutes.completeProfile,
      page: () => CompleteProfileScreen(),
    ),
    GetPage(name: AppRoutes.findPeople, page: () => FindPeopleScreen()),
    GetPage(
      name: AppRoutes.logoutLoading,
      page: () => const LogoutLoadingScreen(),
    ),
    GetPage(
      name: AppRoutes.arCamera,
      page: () => const ArCameraScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.arMediaPreview,
      page: () => const ArMediaPreviewScreen(),
    ),

    // Verification Flow Routes
    GetPage(
      name: AppRoutes.verificationInfo,
      page: () => const VerificationInfoScreen(),
    ),
    GetPage(
      name: AppRoutes.verificationEligibility,
      page: () => const VerificationEligibilityScreen(),
    ),
    GetPage(
      name: AppRoutes.verificationForm,
      page: () => const VerificationFormScreen(),
    ),
    GetPage(
      name: AppRoutes.verificationDocument,
      page: () => const VerificationDocumentScreen(),
    ),
    GetPage(
      name: AppRoutes.verificationSummary,
      page: () => const VerificationSummaryScreen(),
    ),
    GetPage(
      name: AppRoutes.verificationStatus,
      page: () => const VerificationStatusScreen(),
    ),
    GetPage(
      name: AppRoutes.verificationResubmit,
      page: () => const VerificationResubmitScreen(),
    ),

    // Admin & Moderation Routes
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminVerificationDashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.adminVerificationList,
      page: () => const AdminVerificationListScreen(),
    ),
    GetPage(
      name: AppRoutes.adminVerificationDetail,
      page: () => const AdminVerificationDetailScreen(),
    ),
    GetPage(
      name: AppRoutes.adminReportList,
      page: () => const AdminReportListScreen(),
    ),
  ];
}
