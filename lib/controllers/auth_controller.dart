import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';

import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';

class AuthController extends GetxController {
  final ApiService _apiService;

  AuthController({required ApiService apiService}) : _apiService = apiService;

  final isLoading = false.obs;

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
        final msg =
            (body['error_detail'] == 'ETIMEDOUT' ||
                body['message'] == 'Server Error: ')
            ? 'Server is starting up. Please try again in a few seconds.'
            : (body['message'] ?? 'Invalid credentials');
        Get.snackbar('Error', msg);
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
          }

          // If user picked a custom profile image, upload it via PUT /users/:id (which has Multer)
          if (imagePath != null && imagePath.isNotEmpty) {
            print("[AUTH] Uploading selected profile image via UserRepository...");
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
