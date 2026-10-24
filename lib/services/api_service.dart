import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../utils/api_constants.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  static const Duration _defaultTimeout = Duration(seconds: 60);
  Timer? _keepAliveTimer;

  ApiService() {
    _startKeepAliveTimer();
  }

  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    // Keep Render server awake by pinging /health every 5 minutes
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      try {
        final uri = Uri.parse(ApiConstants.health);
        await http.get(uri).timeout(const Duration(seconds: 10));
      } catch (_) {}
    });
  }

  Future<Map<String, String>> _getHeaders({String? url}) async {
    try {
      final isAuthRoute =
          url != null &&
          (url.contains('/auth/login') || url.contains('/auth/register'));

      String? token;
      if (!isAuthRoute) {
        print("ApiService: Reading token from storage...");
        try {
          token = await _storage
              .read(key: 'auth_token')
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          print("ApiService: Token read error: $e");
        }
      }

      if (token != null) {
        print("ApiService: Request token found, length: ${token.length}");
      } else {
        print("ApiService: No request token found (or skipped for auth)");
      }

      return {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print("ApiService: Global error in _getHeaders: $e");
      return {'Content-Type': 'application/json'};
    }
  }

  void _handle401() async {
    if (Get.currentRoute == '/login' || Get.currentRoute == '/register') {
      return;
    }

    print("ApiService: Unauthorized! Clearing token and redirecting to login.");
    await deleteToken();
    Get.snackbar(
      'Session Expired',
      'Please login again to continue.',
      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.currentRoute != '/login') {
        Get.offAllNamed('/login');
      }
    });
  }

  void _handleTimeout(String url) {
    Get.snackbar(
      'Server is waking up',
      'The backend is starting up. This happens after inactivity on free hosting. Please try again in 1 minute.',
      backgroundColor: Colors.orangeAccent.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Helper to retry request on Render cold-start / server wakeup (500/502/503/504, ETIMEDOUT or connection drop)
  Future<http.Response> _withRetry(
    Future<http.Response> Function() requestFn, {
    int maxRetries = 4,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      attempts++;
      try {
        final response = await requestFn();
        final isServerError =
            response.statusCode == 500 ||
            response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 504;

        bool isDbTimeout = false;
        if (isServerError && response.body.isNotEmpty) {
          try {
            final body = jsonDecode(response.body);
            if (body is Map &&
                (body['error_detail'] == 'ETIMEDOUT' ||
                    body['message'] == 'Server Error: ')) {
              isDbTimeout = true;
            }
          } catch (_) {}
        }

        if ((isServerError || isDbTimeout) && attempts < maxRetries) {
          final delaySec = attempts * 3;
          print(
            "ApiService: Server/DB waking up (${response.statusCode} ETIMEDOUT - attempt $attempts), retrying in ${delaySec}s...",
          );
          await Future.delayed(Duration(seconds: delaySec));
          continue;
        }
        return response;
      } on TimeoutException {
        if (attempts < maxRetries) {
          print("ApiService: Request timeout, retrying attempt $attempts...");
          await Future.delayed(Duration(seconds: attempts * 2));
          continue;
        }
        rethrow;
      } catch (e) {
        if (attempts < maxRetries) {
          print(
            "ApiService: Request error ($e), retrying attempt $attempts...",
          );
          await Future.delayed(Duration(seconds: attempts * 2));
          continue;
        }
        rethrow;
      }
    }
    return await requestFn();
  }

  // GET Request
  Future<http.Response> get(String url) async {
    return _withRetry(() async {
      try {
        final headers = await _getHeaders(url: url);
        final uri = Uri.parse(url);
        print("API GET Request: $uri");
        final response = await http
            .get(uri, headers: headers)
            .timeout(_defaultTimeout);
        print("API GET Response [${response.statusCode}]: $uri");

        if (response.statusCode >= 400) {
          print("API Error Body: ${response.body}");
        }

        if (response.statusCode == 401) {
          _handle401();
        }

        return response;
      } on TimeoutException {
        _handleTimeout(url);
        rethrow;
      } catch (e) {
        print("API GET Error ($url): $e");
        rethrow;
      }
    });
  }

  // POST Request
  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    return _withRetry(() async {
      try {
        final headers = await _getHeaders(url: url);
        print("API POST: $url");
        final response = await http
            .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
            .timeout(_defaultTimeout);

        if (response.statusCode >= 400) {
          print("API Error Body: ${response.body}");
        }

        if (response.statusCode == 401) {
          _handle401();
        }

        return response;
      } on TimeoutException {
        _handleTimeout(url);
        rethrow;
      } catch (e) {
        print("API POST Error ($url): $e");
        rethrow;
      }
    });
  }

  // PUT Request
  Future<http.Response> put(String url, Map<String, dynamic> body) async {
    return _withRetry(() async {
      try {
        final headers = await _getHeaders(url: url);
        final response = await http
            .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
            .timeout(_defaultTimeout);

        if (response.statusCode >= 400) {
          print("API Error Body: ${response.body}");
        }

        if (response.statusCode == 401) {
          _handle401();
        }

        return response;
      } on TimeoutException {
        _handleTimeout(url);
        rethrow;
      } catch (e) {
        print("API PUT Error ($url): $e");
        rethrow;
      }
    });
  }

  MediaType _getMediaType(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.heic')) return MediaType('image', 'heic');
    if (lower.endsWith('.mp4')) return MediaType('video', 'mp4');
    if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
    if (lower.endsWith('.avi')) return MediaType('video', 'x-msvideo');
    if (lower.endsWith('.mkv')) return MediaType('video', 'x-matroska');
    return MediaType('image', 'jpeg');
  }

  // Multipart POST Request for File Uploads
  Future<http.Response> postMultipart(
    String url,
    Map<String, String> body,
    String fileKey,
    String filePath,
  ) async {
    return _withRetry(() async {
      try {
        final isAuthRoute = url.contains('/auth/register');
        String? token;
        if (!isAuthRoute) {
          token = await getToken();
        }
        final uri = Uri.parse(url);
        print("API Multipart POST Request: $uri");

        final request = http.MultipartRequest('POST', uri);
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields.addAll(body);

        final mediaTypeObj = _getMediaType(filePath);
        print(
          "ApiService: Attaching file $filePath with Content-Type $mediaTypeObj under key '$fileKey'",
        );
        request.files.add(
          await http.MultipartFile.fromPath(
            fileKey,
            filePath,
            contentType: mediaTypeObj,
          ),
        );

        final streamedResponse = await request.send().timeout(_defaultTimeout);
        final response = await http.Response.fromStream(streamedResponse);

        print("API Multipart Response [${response.statusCode}]: $uri");
        print("API Multipart Response Body: ${response.body}");

        if (response.statusCode >= 400) {
          print("API Multipart Error Body: ${response.body}");
        }

        if (response.statusCode == 401) {
          _handle401();
        }

        return response;
      } on TimeoutException {
        _handleTimeout(url);
        rethrow;
      } catch (e) {
        print("API Multipart Error ($url): $e");
        rethrow;
      }
    });
  }

  // Multipart PUT Request for Profile Updates
  Future<http.Response> putMultipart(
    String url,
    Map<String, String> body,
    String? fileKey,
    String? filePath,
  ) async {
    return _withRetry(() async {
      try {
        final token = await getToken();
        final uri = Uri.parse(url);
        print("API Multipart PUT Request: $uri");

        final request = http.MultipartRequest('PUT', uri);
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields.addAll(body);
        if (fileKey != null && filePath != null) {
          final mediaTypeObj = _getMediaType(filePath);
          request.files.add(
            await http.MultipartFile.fromPath(
              fileKey,
              filePath,
              contentType: mediaTypeObj,
            ),
          );
        }

        final streamedResponse = await request.send().timeout(_defaultTimeout);
        final response = await http.Response.fromStream(streamedResponse);

        print("API Multipart Response [${response.statusCode}]: $uri");

        if (response.statusCode >= 400) {
          print("API Multipart Error Body: ${response.body}");
        }

        if (response.statusCode == 401) {
          _handle401();
        }

        return response;
      } on TimeoutException {
        _handleTimeout(url);
        rethrow;
      } catch (e) {
        print("API Multipart Error ($url): $e");
        rethrow;
      }
    });
  }

  // DELETE Request
  Future<http.Response> delete(String url) async {
    return _withRetry(() async {
      try {
        final headers = await _getHeaders(url: url);
        final response = await http
            .delete(Uri.parse(url), headers: headers)
            .timeout(_defaultTimeout);

        if (response.statusCode >= 400) {
          print("API Error Body: ${response.body}");
        }

        if (response.statusCode == 401) {
          _handle401();
        }

        return response;
      } on TimeoutException {
        _handleTimeout(url);
        rethrow;
      } catch (e) {
        print("API DELETE Error ($url): $e");
        rethrow;
      }
    });
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: 'user_data', value: jsonEncode(user));
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Map<String, dynamic>?> getUser() async {
    String? userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<String?> getUserId() async {
    final user = await getUser();
    if (user != null) {
      return (user['id'] ?? user['uid']).toString();
    }
    return null;
  }
}
