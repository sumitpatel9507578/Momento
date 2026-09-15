import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';

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
          await _apiService.saveToken(token);
          if (userData != null) {
            await _apiService.saveUser(userData);
          }
          Get.snackbar('Success', 'Welcome back to Momento!');
          return true;
        } else {
          print("[AUTH] Error: Success is true but token is null");
          Get.snackbar('Error', 'Invalid server response: Missing token');
          return false;
        }
      } else {
        print("[AUTH] Login failed: ${body['message']}");
        Get.snackbar('Error', body['message'] ?? 'Invalid credentials');
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

      dynamic response;
      if (imagePath != null) {
        // Multipart if local file selected
        response = await _apiService.postMultipart(
          ApiConstants.register,
          {
            'username': username,
            'email': email,
            'password': password,
            'name': name,
            'full_name': name,
          },
          'profileimage',
          imagePath,
        );
      } else {
        // Regular JSON with Gravatar fallback
        response = await _apiService.post(ApiConstants.register, {
          'username': username,
          'email': email,
          'password': password,
          'name': name,
          'full_name': name,
          'profileimage': gravatarUrl,
          'profile_image': gravatarUrl,
          'profileImage': gravatarUrl,
        });
      }

      final body = jsonDecode(response.body);
      print("[AUTH] Register response status: ${response.statusCode}");

      if (body['success'] == true && body['data'] != null) {
        final token = body['data']['token'];
        final userData = body['data']['user'];

        if (token != null) {
          print("[AUTH] Registration token received, length: ${token.length}");
          await _apiService.saveToken(token);
          if (userData != null) {
            await _apiService.saveUser(userData);
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
        Get.snackbar('Error', body['message'] ?? 'Registration failed');
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
