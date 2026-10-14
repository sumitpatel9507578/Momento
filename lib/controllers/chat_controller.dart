import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../models/message_model.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/chat_socket_service.dart';
import '../utils/api_constants.dart';

class ChatController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final ChatSocketService _chatSocket = ChatSocketService(
    apiService: Get.find<ApiService>(),
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final messages = <MessageModel>[].obs;
  final conversations = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isLoadingMessages = false.obs;
  final socketConnected = false.obs;
  final peerOnline = false.obs;
  final peerTyping = false.obs;
  final onlineUserIds = <String>{}.obs;
  final messageLoadError = ''.obs;
  final socketError = ''.obs;

  String? currentUserId;
  final currentUsername = ''.obs;
  String? activeChatUserId;
  Timer? _typingStopTimer;
  bool _typingSent = false;
  List<Map<String, dynamic>> _pendingOutbox = [];

  final savedMessages = <MessageModel>[].obs;
  final savedPosts = <PostModel>[].obs;
  final savedReelsList = <Map<String, dynamic>>[].obs;
  final isLoadingSaved = false.obs;
  final savedItemsError = ''.obs;
  final savingMessageIds = <String>{}.obs;
  final savingPostIds = <String>{}.obs;
  final savingReelIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeRealtimeChat();
    fetchConversations();
    fetchSavedItems();
  }

  Future<void> _initializeRealtimeChat() async {
    currentUserId = await _apiService.getUserId();
    final currentUser = await _apiService.getUser();
    currentUsername.value = (currentUser?['username'] ?? '').toString();
    await _restorePendingOutbox();

    _chatSocket
      ..onConnected = _onSocketConnected
      ..onDisconnected = () {
        socketConnected.value = false;
        peerOnline.value = false;
        peerTyping.value = false;
      }
      ..onConnectionError = (message) {
        socketConnected.value = false;
        socketError.value = message;
      }
      ..onMessage = _onSocketMessage
      ..onTyping = _onTypingUpdate
      ..onRead = _onReadUpdate
      ..onPresenceUpdate = _onPresenceUpdate
      ..onPresenceSnapshot = (ids) {
        onlineUserIds.assignAll(ids.toSet());
        _syncPeerPresence();
      };
    await _chatSocket.connect();
  }

  Future<void> _restorePendingOutbox() async {
    final encoded = await _storage.read(key: 'pending_chat_messages');
    if (encoded == null || encoded.isEmpty) return;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is List) {
        _pendingOutbox = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } on FormatException catch (error) {
      print('Could not restore pending chat messages: $error');
      await _storage.delete(key: 'pending_chat_messages');
    }
  }

  Future<void> _persistPendingOutbox() async {
    await _storage.write(
      key: 'pending_chat_messages',
      value: jsonEncode(_pendingOutbox),
    );
  }

  Future<void> _onSocketConnected() async {
    socketConnected.value = true;
    socketError.value = '';
    await fetchConversations();
    final peerId = activeChatUserId;
    if (peerId != null) {
      _chatSocket.joinConversation(peerId);
      await fetchMessages(peerId);
      _chatSocket.markRead(peerId);
    }
    await _flushPendingMessages();
  }

  void _onSocketMessage(Map<String, dynamic> json) {
    final message = MessageModel.fromJson(json);
    final clientMessageId = message.clientMessageId;
    if (clientMessageId != null) {
      _pendingOutbox.removeWhere(
        (item) => item['clientMessageId'] == clientMessageId,
      );
      _persistPendingOutbox();
    }

    final activePeer = activeChatUserId;
    if (activePeer != null &&
        (message.senderId == activePeer || message.receiverId == activePeer)) {
      _upsertMessage(message.copyWith(isPending: false, isPersisted: true));
      _saveConversationCache(activePeer);
      if (message.senderId == activePeer &&
          message.receiverId == currentUserId) {
        _chatSocket.markRead(activePeer);
      }
    }
    fetchConversations();
  }

  void _onTypingUpdate(Map<String, dynamic> update) {
    if (update['userId']?.toString() == activeChatUserId) {
      peerTyping.value = update['isTyping'] == true;
    }
  }

  void _onReadUpdate(Map<String, dynamic> update) {
    if (update['readerId']?.toString() != activeChatUserId) return;
    messages.assignAll(
      messages
          .map(
            (message) =>
                message.senderId == currentUserId &&
                    message.receiverId == activeChatUserId
                ? message.copyWith(isRead: true)
                : message,
          )
          .toList(),
    );
    _saveConversationCache(activeChatUserId!);
  }

  void _onPresenceUpdate(Map<String, dynamic> update) {
    final userId = update['userId']?.toString();
    if (userId == null) return;
    if (update['isOnline'] == true) {
      onlineUserIds.add(userId);
    } else {
      onlineUserIds.remove(userId);
    }
    _syncPeerPresence();
  }

  void _syncPeerPresence() {
    peerOnline.value =
        activeChatUserId != null && onlineUserIds.contains(activeChatUserId);
  }

  void _upsertMessage(MessageModel message) {
    final index = messages.indexWhere(
      (existing) =>
          existing.id == message.id ||
          (message.clientMessageId != null &&
              existing.clientMessageId == message.clientMessageId),
    );
    if (index == -1) {
      messages.add(message);
    } else {
      messages[index] = message;
    }
    messages.sort((left, right) => left.createdAt.compareTo(right.createdAt));
  }

  List<MessageModel> _pendingFor(String receiverId) => _pendingOutbox
      .where((item) => item['receiverId']?.toString() == receiverId)
      .map(
        (item) => MessageModel.fromJson({
          ...item,
          'id': 'local-${item['clientMessageId']}',
          'senderId': currentUserId ?? '',
          'isPending': true,
          'isPersisted': false,
        }),
      )
      .toList();

  Future<void> _loadConversationCache(String userId) async {
    final encoded = await _storage.read(key: 'chat_cache_$userId');
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          messages.assignAll(
            decoded
                .whereType<Map>()
                .map(
                  (item) => MessageModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(),
          );
        }
      } on FormatException catch (error) {
        print('Could not restore chat history: $error');
        await _storage.delete(key: 'chat_cache_$userId');
      }
    }
    for (final pending in _pendingFor(userId)) {
      _upsertMessage(pending);
    }
  }

  Future<void> _saveConversationCache(String userId) async {
    final persisted = messages
        .where((message) => message.isPersisted && !message.isPending)
        .toList();
    final recent = persisted.length > 200
        ? persisted.sublist(persisted.length - 200)
        : persisted;
    await _storage.write(
      key: 'chat_cache_$userId',
      value: jsonEncode(recent.map((message) => message.toJson()).toList()),
    );
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
      final postItems = items
          .whereType<Map>()
          .where((item) => item['itemType'] == 'post')
          .map(
            (item) => PostModel.fromJson({
              ...Map<String, dynamic>.from(item),
              'id': item['itemId'],
              'isSaved': true,
            }),
          )
          .toList();
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

      savedPosts.assignAll(postItems);
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

  Future<bool> toggleSavePost(String postId, {required bool isSaved}) async {
    if (int.tryParse(postId) == null) {
      Get.snackbar('Error', 'This post does not have a valid saved ID');
      return false;
    }
    if (savingPostIds.contains(postId)) return false;
    savingPostIds.add(postId);
    try {
      final endpoint = '${ApiConstants.savedItems}/posts/$postId';
      final response = isSaved
          ? await _apiService.delete(endpoint)
          : await _apiService.post(endpoint, const {});
      final decoded = _decodeResponse(response.body);
      if (response.statusCode != 200 || decoded?['success'] != true) {
        Get.snackbar(
          'Error',
          decoded?['message']?.toString() ?? 'Failed to update saved post',
        );
        return false;
      }

      await fetchSavedItems();
      Get.snackbar(
        'Success',
        isSaved ? 'Post removed from saved items' : 'Post saved',
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong while saving post');
      return false;
    } finally {
      savingPostIds.remove(postId);
    }
  }

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
    _typingStopTimer?.cancel();
    _chatSocket.disconnect();
    super.onClose();
  }

  void startLiveMessages(String userId) {
    final parsedUserId = int.tryParse(userId);
    if (parsedUserId == null || parsedUserId <= 0) {
      messageLoadError.value = 'This chat does not have a valid user ID.';
      return;
    }
    activeChatUserId = userId;
    messageLoadError.value = '';
    peerTyping.value = false;
    _syncPeerPresence();
    messages.clear();
    _loadConversationCache(userId).then((_) {
      if (activeChatUserId == userId) fetchMessages(userId);
    });
    if (_chatSocket.isConnected) _chatSocket.joinConversation(userId);
  }

  void stopLiveMessages() {
    final peerId = activeChatUserId;
    if (_typingSent && peerId != null) {
      _chatSocket.setTyping(peerId, false);
    }
    _typingStopTimer?.cancel();
    _typingSent = false;
    activeChatUserId = null;
    peerTyping.value = false;
    peerOnline.value = false;
  }

  void onMessageInput(String receiverId, bool hasText) {
    _typingStopTimer?.cancel();
    if (!socketConnected.value) return;
    if (hasText && !_typingSent) {
      _typingSent = true;
      _chatSocket.setTyping(receiverId, true);
    } else if (!hasText && _typingSent) {
      _typingSent = false;
      _chatSocket.setTyping(receiverId, false);
    }
    if (hasText) {
      _typingStopTimer = Timer(const Duration(seconds: 2), () {
        _typingSent = false;
        _chatSocket.setTyping(receiverId, false);
      });
    }
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
      } else {
        print('Could not load conversations: ${response.body}');
      }
    } catch (error) {
      print('Error fetching conversations: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMessages(String userId) async {
    try {
      messageLoadError.value = '';
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
        for (final pending in _pendingFor(userId)) {
              _upsertMessage(pending);
        }
        await _saveConversationCache(userId);
      } else {
        final decoded = _decodeResponse(response.body);
        messageLoadError.value =
                decoded?['message']?.toString() ??
                'Could not load this conversation.';
      }
    } catch (e) {
      print("Error fetching messages: $e");
      messageLoadError.value =
              'Could not connect to the chat server. Showing saved messages.';
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<bool> sendMessage(
    String receiverId,
    String text, {
    String? reelId,
    String? postId,
    String? mediaUrl,
    String? messageTypeOverride,
  }) async {
    final myId = currentUserId ?? (await _apiService.getUserId()) ?? '';
    final parsedReceiverId = int.tryParse(receiverId);
    if (parsedReceiverId == null ||
        parsedReceiverId <= 0 ||
        myId.isEmpty ||
        receiverId == myId) {
      Get.snackbar(
        'Message not sent',
        'This conversation has an invalid user. Open the profile again.',
      );
      return false;
    }
    final messageType =
        messageTypeOverride ??
        (reelId != null
            ? 'reel'
            : postId != null
            ? 'post'
            : 'text');
    if (!['text', 'image', 'video', 'reel'].contains(messageType) ||
        ((messageType == 'image' || messageType == 'video') &&
            (mediaUrl == null || mediaUrl.isEmpty))) {
      Get.snackbar('Message not sent', 'This message type is not supported.');
      return false;
    }
    final clientMessageId =
        '${myId}_${receiverId}_${DateTime.now().microsecondsSinceEpoch}';
    final payload = <String, dynamic>{
      'receiverId': receiverId,
      'message': text,
      'messageType': messageType,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'clientMessageId': clientMessageId,
      'createdAt': DateTime.now().toIso8601String(),
      if (reelId != null) 'reelId': reelId,
      if (postId != null) 'postId': postId,
    };

    _pendingOutbox.add(payload);
    await _persistPendingOutbox();
    if (activeChatUserId == receiverId) {
      _upsertMessage(
        MessageModel(
          id: 'local-$clientMessageId',
          clientMessageId: clientMessageId,
          senderId: myId,
          receiverId: receiverId,
          message: text,
          messageType: messageType,
          mediaUrl: mediaUrl,
          reelId: reelId,
          createdAt: DateTime.now(),
          isRead: false,
          isPersisted: false,
          isPending: true,
        ),
      );
      _saveConversationCache(receiverId);
    }
    if (!socketConnected.value) return true;
    return _deliverPendingMessage(payload);
  }

  Future<bool> sendImage(String receiverId, String filePath) async {
    try {
      final response = await _apiService.postMultipart(
        '${ApiConstants.messages}/upload',
        const {},
        'media',
        filePath,
      );
      final decoded = _decodeResponse(response.body);
      if (response.statusCode != 201 || decoded?['success'] != true) {
        Get.snackbar(
          'Photo not sent',
          decoded?['message']?.toString() ?? 'Could not upload this photo.',
        );
        return false;
      }
      final data = decoded?['data'];
      if (data is! Map ||
          data['mediaUrl'] == null ||
          data['messageType'] != 'image') {
        Get.snackbar('Photo not sent', 'The server returned an invalid upload.');
        return false;
      }
      return await sendMessage(
        receiverId,
        '',
        mediaUrl: data['mediaUrl'].toString(),
        messageTypeOverride: 'image',
      );
    } catch (error) {
      print('Error uploading chat image: $error');
      Get.snackbar('Photo not sent', 'Could not upload this photo.');
      return false;
    }
  }

  Future<void> _flushPendingMessages() async {
    for (final item in List<Map<String, dynamic>>.from(_pendingOutbox)) {
      if (!socketConnected.value) return;
      await _deliverPendingMessage(item);
    }
  }

  Future<bool> _deliverPendingMessage(Map<String, dynamic> payload) async {
    final response = await _chatSocket.sendMessage(payload);
    if (response == null) return true;
    if (response['success'] != true || response['data'] is! Map) {
      final code = response['code']?.toString();
      final clientMessageId = payload['clientMessageId']?.toString();
      if (code == 'RECEIVER_NOT_FOUND' ||
          code == 'USER_NOT_FOUND' ||
          code == 'INVALID_MESSAGE' ||
          code == 'CHAT_IDEMPOTENCY_MIGRATION_REQUIRED' ||
          code == 'REEL_MESSAGE_MIGRATION_REQUIRED') {
        _pendingOutbox.removeWhere(
          (item) => item['clientMessageId'] == clientMessageId,
        );
        messages.removeWhere(
          (message) => message.clientMessageId == clientMessageId,
        );
        await _persistPendingOutbox();
      }
      final errorMessage =
          response['message']?.toString() ?? 'Message could not be delivered.';
      Get.snackbar('Message not sent', errorMessage);
      return false;
    }

    final message = MessageModel.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    final clientMessageId = payload['clientMessageId']?.toString();
    _pendingOutbox.removeWhere(
      (item) => item['clientMessageId'] == clientMessageId,
    );
    await _persistPendingOutbox();
    if (activeChatUserId == message.receiverId) {
      _upsertMessage(message.copyWith(isPending: false, isPersisted: true));
      await _saveConversationCache(message.receiverId);
    }
    fetchConversations();
    return true;
  }
}
