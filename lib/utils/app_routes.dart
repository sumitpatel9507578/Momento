import 'package:get/get.dart';

import '../views/home_screen.dart';
import '../views/login_screen.dart';
import '../views/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';

  static List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: home, page: () => HomeScreen()),
  ];
}
