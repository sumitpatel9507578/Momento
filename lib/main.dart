import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:momento/services/google_auth_service.dart';

import 'bindings/app_binding.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final googleAuthService = GoogleAuthService();

  await googleAuthService.initialize();

  Get.put<GoogleAuthService>(googleAuthService);

  runApp(const MomentoApp());
}

class MomentoApp extends StatelessWidget {
  const MomentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Momento',
      theme: AppTheme.darkTheme,
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
