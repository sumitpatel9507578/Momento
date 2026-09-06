import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService;
  final GoogleAuthService _googleAuthService;
  final UserRepository _userRepository = UserRepository();

  AuthController({
    required this._authService,
    required this._googleAuthService,
  });

  final isLoading = false.obs;

  Future<bool> login({required String email, required String password}) async {
    try {
      isLoading.value = true;

      await _authService.login(email: email, password: password);

      return true;
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final credential = await _authService.register(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('User creation failed.');
      }

      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        username: username.trim().toLowerCase(),
        email: email.trim(),
        profileImage: '',
        bio: 'Every moment has a story ',
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        createdAt: DateTime.now(),
      );

      await _userRepository.createUserProfile(userModel);

      return true;
    } catch (e) {
      Get.snackbar(
        'Registration Failed',
        e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> googleLogin() async {
    try {
      isLoading.value = true;

      final UserCredential credential = await _googleAuthService
          .signInWithGoogle();

      final User? user = credential.user;

      if (user == null) {
        throw Exception('Google user information not found.');
      }

      final existingUser = await _userRepository.getUserById(user.uid);

      if (existingUser == null) {
        final displayName = user.displayName?.trim() ?? '';
        final email = user.email?.trim() ?? '';
        final photoUrl = user.photoURL ?? '';

        final baseUsername = _generateUsername(
          displayName: displayName,
          email: email,
          uid: user.uid,
        );

        final userModel = UserModel(
          uid: user.uid,
          name: displayName.isEmpty ? 'Momento User' : displayName,
          username: baseUsername,
          email: email,
          profileImage: photoUrl,
          bio: 'Every moment has a story ✨',
          followersCount: 0,
          followingCount: 0,
          postsCount: 0,
          createdAt: DateTime.now(),
        );

        await _userRepository.createUserProfile(userModel);
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Google Sign-In Failed',
        e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      isLoading.value = true;

      await _authService.forgotPassword(email);

      return true;
    } catch (e) {
      Get.snackbar(
        'Password Reset Failed',
        e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _googleAuthService.signOut();
  }

  String _generateUsername({
    required String displayName,
    required String email,
    required String uid,
  }) {
    String base = '';
    if (displayName.isNotEmpty) {
      base = displayName.toLowerCase().replaceAll(' ', '_');
    } else {
      base = email.split('@')[0].toLowerCase();
    }
    return '${base}_${uid.substring(0, 5)}';
  }
}
