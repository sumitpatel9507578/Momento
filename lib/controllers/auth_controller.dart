import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';

class AuthController extends GetxController {
  final ApiService _apiService;

  AuthController({required this._apiService});

  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      final userMap = await _apiService.getUser();
      if (userMap != null) {
        currentUser.value = UserModel.fromMap(userMap);
      }
    } catch (_) {}
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      print("[AUTH] Login started for $email");

      final response = await _apiService.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });

      final body = jsonDecode(response.body);
      print("[AUTH] Login response status: ${response.statusCode}");

      if (body['success'] == true && body['data'] != null) {
        final token = body['data']['token'];
        final userData = body['data']['user'];

        if (token != null) {
          print("[AUTH] Token received, length: ${token.length}");
          await _apiService.saveToken(token.toString());
          if (userData != null) {
            await _apiService.saveUser(userData);
            currentUser.value = UserModel.fromMap(userData);
          }
          print("[AUTH] Token saved successfully in FlutterSecureStorage");
          Get.snackbar('Success', 'Welcome back to Momento!');
          return true;
        } else {
          print("[AUTH] Error: Success is true but token is null");
          Get.snackbar('Error', 'Invalid server response: Missing token');
          return false;
        }
      } else {
        print("[AUTH] Login failed: ${body['message']}");
        String msg = body['message'] ?? '';

        if (body['error_detail'] == 'ETIMEDOUT' ||
            msg.contains('ETIMEDOUT') ||
            msg.contains('Server Error: ')) {
          msg = 'Server is starting up. Please try again in a few seconds.';
        } else if (msg.toLowerCase().contains('invalid') ||
            msg.toLowerCase().contains('credential') ||
            msg.toLowerCase().contains('password')) {
          msg = 'Wrong email or password. Please try again.';
        } else if (msg.toLowerCase().contains('not found') ||
            msg.toLowerCase().contains('user')) {
          msg = 'No account found with this email.';
        } else if (msg.isEmpty) {
          msg = 'Wrong email or password. Please check your credentials.';
        }

        Get.snackbar('Login Failed', msg);
        return false;
      }
    } catch (e) {
      print("[AUTH] Login exception: $e");
      Get.snackbar(
        'Error',
        'Something went wrong. Please check your connection.',
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
    String? imagePath,
  }) async {
    try {
      isLoading.value = true;
      print("[AUTH] Registration started for $email");

      final gravatarUrl = getEmailAvatarUrl(email);

      // Backend /auth/register is a JSON endpoint expecting application/json
      final response = await _apiService.post(ApiConstants.register, {
        'username': username,
        'email': email,
        'password': password,
        'name': name,
        'full_name': name,
        'profileimage': gravatarUrl,
        'profile_image': gravatarUrl,
        'profileImage': gravatarUrl,
      });

      Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = {
          'success': false,
          'message': 'Server response invalid. Please try again.',
        };
      }
      print("[AUTH] Register response status: ${response.statusCode}");

      if (body['success'] == true && body['data'] != null) {
        final token = body['data']['token'];
        final userData = body['data']['user'];

        if (token != null) {
          print("[AUTH] Registration token received, length: ${token.length}");
          await _apiService.saveToken(token.toString());
          if (userData != null) {
            await _apiService.saveUser(userData);
            currentUser.value = UserModel.fromMap(userData);
          }

          // If user picked a custom profile image, upload it via PUT /users/:id (which has Multer)
          if (imagePath != null && imagePath.isNotEmpty) {
            print(
              "[AUTH] Uploading selected profile image via UserRepository...",
            );
            final userRepository = UserRepository();
            await userRepository.updateProfile({}, imagePath);
          }

          Get.snackbar('Success', 'Registration successful');
          return true;
        } else {
          print("[AUTH] Error: Success is true but token is null");
          Get.snackbar('Error', 'Registration failed: Missing token');
          return false;
        }
      } else {
        print("[AUTH] Registration failed: ${body['message']}");
        final msg =
            (body['error_detail'] == 'ETIMEDOUT' ||
                body['message'] == 'Server Error: ')
            ? 'Server is starting up. Please try again in a few seconds.'
            : (body['message'] ?? 'Registration failed');
        Get.snackbar('Error', msg);
        return false;
      }
    } catch (e) {
      print("[AUTH] Register exception: $e");
      Get.snackbar(
        'Error',
        'Something went wrong. Please check your connection.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      isLoading.value = true;
      print("[AUTH] Google Sign In requested...");

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled sign-in
        isLoading.value = false;
        return false;
      }

      final email = googleUser.email;
      final displayName = googleUser.displayName ?? 'Google User';
      final googleId = googleUser.id;
      final photoUrl = googleUser.photoUrl;

      // Deterministic password for backend auth
      final googlePassword = "GooglePass_${googleId}_MomentoSec!";
      final username = email.contains('@')
          ? email.split('@')[0]
          : 'user_$googleId';

      print("[AUTH] Google User obtained: $email ($displayName)");

      // Step 1: Try login with Google credentials
      final loginSuccess = await _tryGoogleLogin(email, googlePassword);
      if (loginSuccess) return true;

      // Step 2: If user does not exist on backend yet, auto-register them
      print("[AUTH] User not registered yet. Auto-registering Google user...");
      final regSuccess = await _tryGoogleRegister(
        name: displayName,
        username: username,
        email: email,
        password: googlePassword,
        photoUrl: photoUrl,
      );

      return regSuccess;
    } catch (e) {
      print("[AUTH] Google Sign In Exception: $e");
      Get.snackbar(
        'Google Sign In',
        'Could not complete Google Sign In. Try again or login manually.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _tryGoogleLogin(String email, String password) async {
    try {
      final response = await _apiService.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });

      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        final token = body['data']['token'];
        final userData = body['data']['user'];
        if (token != null) {
          await _apiService.saveToken(token.toString());
          if (userData != null) {
            await _apiService.saveUser(userData);
            currentUser.value = UserModel.fromMap(userData);
          }
          Get.snackbar('Success', 'Logged in with Google!');
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _tryGoogleRegister({
    required String name,
    required String username,
    required String email,
    required String password,
    String? photoUrl,
  }) async {
    try {
      final avatar = (photoUrl != null && photoUrl.isNotEmpty)
          ? photoUrl
          : getEmailAvatarUrl(email);

      final response = await _apiService.post(ApiConstants.register, {
        'username': username,
        'email': email,
        'password': password,
        'name': name,
        'full_name': name,
        'profileimage': avatar,
        'profile_image': avatar,
        'profileImage': avatar,
      });

      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        final token = body['data']['token'];
        final userData = body['data']['user'];
        if (token != null) {
          await _apiService.saveToken(token.toString());
          if (userData != null) {
            await _apiService.saveUser(userData);
            currentUser.value = UserModel.fromMap(userData);
          }
          Get.snackbar('Success', 'Account created via Google!');
          return true;
        }
      }
    } catch (e) {
      print("[AUTH] Google register error: $e");
    }
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post(
        "${ApiConstants.baseUrl}/auth/forgot-password",
        {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      Get.snackbar('Error', 'Failed to send reset email');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    currentUser.value = null;
    await _apiService.deleteToken();
    Get.offAllNamed('/login');
  }

  String getEmailAvatarUrl(String email) {
    final emailHash = md5
        .convert(utf8.encode(email.trim().toLowerCase()))
        .toString();
    return 'https://www.gravatar.com/avatar/$emailHash?d=identicon&s=200';
  }
}
