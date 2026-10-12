import 'dart:async';
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
  String? activeChatUserId;
  Timer? _livePollingTimer;

  final savedMessages = <MessageModel>[].obs;
  final savedReelsList = <Map<String, dynamic>>[].obs;
  final isLoadingSaved = false.obs;
  final savedItemsError = ''.obs;
  final savingMessageIds = <String>{}.obs;
  final savingReelIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initUser();
    fetchConversations();
    fetchSavedItems();
  }

  Future<void> fetchSavedItems() async {
    try {
      isLoadingSaved.value = true;
      final response = await _apiService.get(ApiConstants.savedItems);
      final decoded = _decodeResponse(response.body);
      if (response.statusCode != 200 || decoded?['success'] != true) {
        savedItemsError.value =
            decoded?['message']?.toString() ?? 'Could not load saved items';
        return;
      }

      final List<dynamic> items = decoded?['data'] is List
          ? decoded!['data'] as List<dynamic>
          : <dynamic>[];
      final messageItems = items
          .whereType<Map>()
          .where((item) => item['itemType'] == 'message')
          .map(
            (item) => MessageModel.fromJson({
              ...Map<String, dynamic>.from(item),
              'id': item['itemId'],
              'isSaved': true,
            }),
          )
          .toList();
      final reelItems = items
          .whereType<Map>()
          .where((item) => item['itemType'] == 'reel')
          .map((item) {
            final reel = Map<String, dynamic>.from(item);
            reel['id'] = item['itemId'];
            reel['isSaved'] = true;
            return reel;
          })
          .toList();

      savedMessages.assignAll(messageItems);
      savedReelsList.assignAll(reelItems);
      savedItemsError.value = '';
      _syncSavedMessageFlags();
    } catch (e) {
      print("Error fetching saved items: $e");
      savedItemsError.value = 'Could not load saved items. Please try again.';
    } finally {
      isLoadingSaved.value = false;
    }
  }

  void _syncSavedMessageFlags() {
    final savedIds = savedMessages.map((message) => message.id).toSet();
    messages.assignAll(
      messages
          .map(
            (message) =>
                message.copyWith(isSaved: savedIds.contains(message.id)),
          )
          .toList(),
    );
  }

  bool isReelSaved(String reelId) => savedReelsList.any(
    (reel) =>
        (reel['itemId'] ?? reel['id'] ?? reel['reelId']).toString() == reelId,
  );

  Map<String, dynamic>? _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<bool> toggleSaveMessage(MessageModel msg) async {
    final messageId = msg.id;
    if (!msg.isPersisted || int.tryParse(messageId) == null) {
      Get.snackbar(
        'Error',
        'Wait until the message is saved before bookmarking it',
      );
      return false;
    }
    if (savingMessageIds.contains(messageId)) return false;
    final isCurrentlySaved = msg.isSaved;
    savingMessageIds.add(messageId);

    try {
      final endpoint = "${ApiConstants.savedItems}/messages/$messageId";
      final response = isCurrentlySaved
          ? await _apiService.delete(endpoint)
          : await _apiService.post(endpoint, const {});
      final decoded = _decodeResponse(response.body);
      if (response.statusCode != 200 || decoded?['success'] != true) {
        Get.snackbar(
          'Error',
          decoded?['message']?.toString() ??
              'Could not update message save state',
        );
        return false;
      }

      final index = messages.indexWhere((message) => message.id == messageId);
      if (index != -1) {
        messages[index] = messages[index].copyWith(isSaved: !isCurrentlySaved);
      }
      await fetchSavedItems();
      Get.snackbar(
        'Success',
        isCurrentlySaved ? 'Message removed from saved' : 'Message saved',
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to save message');
      return false;
    } finally {
      savingMessageIds.remove(messageId);
    }
  }

  Future<bool> toggleSaveReel(String reelId, {required bool isSaved}) async {
    if (int.tryParse(reelId) == null) {
      Get.snackbar('Error', 'This reel does not have a valid saved ID');
      return false;
    }
    if (savingReelIds.contains(reelId)) return false;
    savingReelIds.add(reelId);
    try {
      final endpoint = "${ApiConstants.savedItems}/reels/$reelId";
      final response = isSaved
          ? await _apiService.delete(endpoint)
          : await _apiService.post(endpoint, const {});
      final decoded = _decodeResponse(response.body);
      if (response.statusCode != 200 || decoded?['success'] != true) {
        Get.snackbar(
          'Error',
          decoded?['message']?.toString() ?? 'Failed to update saved reel',
        );
        return false;
      }

      await fetchSavedItems();
      Get.snackbar(
        'Success',
        isSaved ? 'Reel removed from saved items' : 'Reel saved',
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong while saving reel');
      return false;
    } finally {
      savingReelIds.remove(reelId);
    }
  }

  @override
  void onClose() {
    stopLiveMessages();
    super.onClose();
  }

  Future<void> _initUser() async {
    currentUserId = await _apiService.getUserId();
  }

  void startLiveMessages(String userId) {
    activeChatUserId = userId;
    fetchMessages(userId);

    _livePollingTimer?.cancel();
    _livePollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (activeChatUserId != null && activeChatUserId!.isNotEmpty) {
        _silentFetchMessages(activeChatUserId!);
      }
    });
  }

  void stopLiveMessages() {
    _livePollingTimer?.cancel();
    _livePollingTimer = null;
    activeChatUserId = null;
  }

  Future<void> _silentFetchMessages(String userId) async {
    try {
      final response = await _apiService.get(
        "${ApiConstants.messages}/$userId",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List msgs = data['data'] ?? data['messages'] ?? [];
        messages.assignAll(
          msgs
              .map((m) => MessageModel.fromJson(m))
              .map(
                (message) => message.copyWith(
                  isSaved: savedMessages.any((saved) => saved.id == message.id),
                ),
              ),
        );
      }
    } catch (_) {}
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
      if (messages.isEmpty) {
        isLoadingMessages.value = true;
      }
      final response = await _apiService.get(
        "${ApiConstants.messages}/$userId",
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List msgs = data['data'] ?? data['messages'] ?? [];
        messages.assignAll(
          msgs
              .map((m) => MessageModel.fromJson(m))
              .map(
                (message) => message.copyWith(
                  isSaved: savedMessages.any((saved) => saved.id == message.id),
                ),
              ),
        );
      }
    } catch (e) {
      print("Error fetching messages: $e");
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<bool> sendMessage(
    String receiverId,
    String text, {
    String? reelId,
  }) async {
    final myId = currentUserId ?? (await _apiService.getUserId()) ?? '';
    final tempMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: myId,
      receiverId: receiverId,
      message: text,
      messageType: reelId == null ? 'text' : 'reel',
      reelId: reelId,
      createdAt: DateTime.now(),
      isRead: false,
      isPersisted: false,
    );

    // Optimistic UI update: append message locally immediately
    messages.add(tempMsg);

    try {
      final payload = <String, dynamic>{
        'receiverId': receiverId,
        'message': text,
        'messageType': reelId == null ? 'text' : 'reel',
        if (reelId != null) 'reelId': reelId,
      };

      final response = await _apiService.post(ApiConstants.messages, payload);
      final decoded = _decodeResponse(response.body);

      print(
        "Send Message -> status ${response.statusCode}, body: ${response.body}",
      );

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          decoded?['success'] == true) {
        await fetchMessages(receiverId);
        return true;
      }

      messages.removeWhere((message) => message.id == tempMsg.id);
      return false;
    } catch (e) {
      print("Send Message Error: $e");
      messages.removeWhere((message) => message.id == tempMsg.id);
      return false;
    }
  }
}
