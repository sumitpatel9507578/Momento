import 'dart:convert';

import 'package:get/get.dart';

import '../models/message_model.dart';
import '../services/api_service.dart';
import '../utils/api_constants.dart';

class ChatController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final messages = <MessageModel>[].obs;
  final conversations = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isLoadingMessages = false.obs;

  String? currentUserId;

  @override
  void onInit() {
    super.onInit();
    _initUser();
    fetchConversations();
  }

  Future<void> _initUser() async {
    currentUserId = await _apiService.getUserId();
  }

  Future<void> fetchConversations() async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        "${ApiConstants.messages}/conversations",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List convos = data['data'] ?? [];
        conversations.assignAll(List<Map<String, dynamic>>.from(convos));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMessages(String userId) async {
    try {
      isLoadingMessages.value = true;
      final response = await _apiService.get(
        "${ApiConstants.messages}/$userId",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List msgs = data['data'] ?? [];
        messages.assignAll(msgs.map((m) => MessageModel.fromJson(m)).toList());
      }
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<bool> sendMessage(String receiverId, String text) async {
    try {
      final response = await _apiService.post(ApiConstants.messages, {
        'receiverId': receiverId,
        'message': text,
        'messageType': 'text',
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        fetchMessages(receiverId); // Refresh conversation
        return true;
      }
      return false;
    } catch (e) {
      print("Send Message Error: $e");
      return false;
    }
  }
}
