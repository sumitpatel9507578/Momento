import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:momento/models/message_model.dart';
import 'package:momento/models/post_model.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/services/chat_socket_service.dart';
import 'package:momento/utils/api_constants.dart';

class ChatController extends GetxController with WidgetsBindingObserver {
  final ApiService _apiService = Get.find<ApiService>();
  late final ChatSocketService _chatSocket;
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
  final showActivityStatus = true.obs;

  String? currentUserId;
  final currentUsername = ''.obs;
  String? activeChatUserId;

  String get receiverId => activeChatUserId ?? '';
  final receiverName = ''.obs;
  final receiverAvatar = ''.obs;

  Timer? _typingStopTimer;
  Timer? _typingAutoClearTimer;
  Timer? _heartbeatTimer;
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

  int get totalUnreadCount {
    int total = 0;
    for (final conv in conversations) {
      final count = conv['unreadCount'] ?? conv['unread_count'] ?? conv['unread'] ?? 0;
      if (count is int) {
        total += count;
      } else if (count != null) {
        total += int.tryParse(count.toString()) ?? 0;
      }
    }
    return total;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _chatSocket = Get.isRegistered<ChatSocketService>()
        ? Get.find<ChatSocketService>()
        : Get.put(ChatSocketService(apiService: _apiService), permanent: true);

    _loadActivityStatus();
    _initializeRealtimeChat();
    fetchConversations();
    fetchSavedItems();
    _startHeartbeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      debugPrint('[APP] App backgrounded -> disconnecting socket');
      _chatSocket.disconnect();
      socketConnected.value = false;
      peerOnline.value = false;
      peerTyping.value = false;
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[APP] App resumed -> reconnecting socket');
      _reconnectAndSync();
    }
  }

  Future<void> _reconnectAndSync() async {
    await _chatSocket.connect();
    final peerId = activeChatUserId;
    if (peerId != null) {
      _chatSocket.joinConversation(peerId);
      await fetchMessages(peerId);
      _chatSocket.markRead(peerId);
    }
    if (showActivityStatus.value) {
      _chatSocket.emitPresenceOnline();
    }
    fetchConversations();
  }

  Future<void> _loadActivityStatus() async {
    final val = await _storage.read(key: 'show_activity_status');
    if (val != null) {
      showActivityStatus.value = val == 'true';
    }
  }

  Future<void> toggleActivityStatus(bool value) async {
    showActivityStatus.value = value;
    await _storage.write(key: 'show_activity_status', value: value.toString());
    if (socketConnected.value) {
      if (value) {
        _chatSocket.emitPresenceOnline();
      } else {
        _chatSocket.emitPresenceOffline();
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (socketConnected.value && showActivityStatus.value) {
        _chatSocket.emitPing();
      }
    });
  }

  Future<void> _initializeRealtimeChat() async {
    currentUserId = await _apiService.getUserId();
    final currentUser = await _apiService.getUser();
    currentUsername.value = (currentUser?['username'] ?? '').toString();
    await _restorePendingOutbox();

    // Bind reactive online user IDs directly from socket service
    onlineUserIds.bindStream(_chatSocket.onlineUserIds.stream);

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
      ..onMessageUnsent = _onSocketMessageUnsent
      ..onPresenceUpdate = _onPresenceUpdate
      ..onPresenceSnapshot = (ids) {
        _syncPeerPresence();
      };

    await _chatSocket.connect();
  }

  bool isUserOnline(String? userId) => _chatSocket.isUserOnline(userId);

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
      debugPrint('Could not restore pending chat messages: $error');
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
    debugPrint('[CHAT] Processing incoming socket message: $json');
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
      _upsertMessage(
        message.copyWith(isPending: false, sendError: false, isPersisted: true),
      );
      _saveConversationCache(activePeer);
      if (message.senderId == activePeer &&
          message.receiverId == currentUserId) {
        _chatSocket.markRead(activePeer);
      }
    }

    _updateConversationForIncomingMessage(message);
  }

  void _updateConversationForIncomingMessage(MessageModel message) {
    final otherUserId = message.senderId == currentUserId
        ? message.receiverId
        : message.senderId;
    final index = conversations.indexWhere((c) {
      final cId =
          (c['conversationUserId'] ??
                  c['conversation_user_id'] ??
                  c['userId'] ??
                  c['id'])
              ?.toString();
      return cId == otherUserId;
    });

    final isFromActiveChat = activeChatUserId == otherUserId;
    final isUnread = !isFromActiveChat && message.senderId != currentUserId;

    if (index != -1) {
      final existing = Map<String, dynamic>.from(conversations[index]);
      existing['lastMessage'] = message.message;
      existing['lastMessageTime'] = message.createdAt.toIso8601String();
      existing['messageType'] = message.messageType;
      existing['isRead'] = !isUnread;
      existing['unread'] = isUnread;
      conversations.removeAt(index);
      conversations.insert(0, existing);
    } else {
      fetchConversations();
    }
  }

  void _onTypingUpdate(Map<String, dynamic> update) {
    final senderId =
        (update['userId'] ?? update['senderId'] ?? update['user_id'])
            ?.toString();
    if (senderId == activeChatUserId) {
      final isTyping =
          update['isTyping'] == true || update['is_typing'] == true;
      peerTyping.value = isTyping;

      _typingAutoClearTimer?.cancel();
      if (isTyping) {
        _typingAutoClearTimer = Timer(const Duration(seconds: 5), () {
          peerTyping.value = false;
        });
      }
    }
  }

  void _onReadUpdate(Map<String, dynamic> update) {
    final readerId =
        (update['readerId'] ?? update['senderId'] ?? update['userId'])
            ?.toString();
    if (readerId == activeChatUserId) {
      final updated = messages.map((msg) {
        if (msg.senderId == currentUserId &&
            msg.receiverId == activeChatUserId) {
          return msg.copyWith(isRead: true);
        }
        return msg;
      }).toList();
      messages.assignAll(updated);
      if (activeChatUserId != null) {
        _saveConversationCache(activeChatUserId!);
      }
    }
  }

  void _onSocketMessageUnsent(Map<String, dynamic> update) {
    debugPrint('[CHAT] Processing unsent socket message: $update');
    final messageId = (update['messageId'] ?? update['id'] ?? update['_id'])
        ?.toString();
    final clientMsgId = update['clientMessageId']?.toString();

    if (messageId != null || clientMsgId != null) {
      messages.removeWhere(
        (msg) =>
            (messageId != null &&
                messageId.isNotEmpty &&
                msg.id == messageId) ||
            (clientMsgId != null &&
                clientMsgId.isNotEmpty &&
                msg.clientMessageId == clientMsgId),
      );
      if (activeChatUserId != null) {
        _saveConversationCache(activeChatUserId!);
      }
      fetchConversations();
    }
  }

  void _onPresenceUpdate(Map<String, dynamic> update) {
    _syncPeerPresence();
  }

  void _syncPeerPresence() {
    final peerId = activeChatUserId;
    if (peerId == null) {
      peerOnline.value = false;
      return;
    }
    peerOnline.value = _chatSocket.isUserOnline(peerId);
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
          'sendError': false,
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
                  (item) =>
                      MessageModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(),
          );
        }
      } on FormatException catch (error) {
        debugPrint('Could not restore chat history: $error');
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
      debugPrint("Error fetching saved items: $e");
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
    if (reelId.trim().isEmpty) {
      Get.snackbar('Error', 'Invalid reel ID');
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
        // Fallback endpoint POST /api/reels/{id}/save
        try {
          final fallbackEndpoint = "${ApiConstants.reels}/$reelId/save";
          final fallbackResp = isSaved
              ? await _apiService.delete(fallbackEndpoint)
              : await _apiService.post(fallbackEndpoint, const {});
          if (fallbackResp.statusCode >= 200 && fallbackResp.statusCode < 300) {
            await fetchSavedItems();
            Get.snackbar(
              'Success',
              isSaved ? 'Reel removed from saved items' : 'Reel saved',
            );
            return true;
          }
        } catch (_) {}
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
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _typingAutoClearTimer?.cancel();
    _typingStopTimer?.cancel();
    stopLiveMessages();
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
    if (_chatSocket.isConnected) {
      _chatSocket.joinConversation(userId);
      _chatSocket.markRead(userId);
    }
  }

  void stopLiveMessages() {
    final peerId = activeChatUserId;
    if (_typingSent && peerId != null) {
      _chatSocket.setTyping(peerId, false);
    }
    _typingStopTimer?.cancel();
    _typingAutoClearTimer?.cancel();
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
        debugPrint('Could not load conversations: ${response.body}');
      }
    } catch (error) {
      debugPrint('Error fetching conversations: $error');
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
      debugPrint("Error fetching messages: $e");
      messageLoadError.value =
          'Could not connect to the chat server. Showing saved messages.';
    } finally {
      isLoadingMessages.value = false;
    }
  }

  String _generateClientMessageId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(900000) + 100000;
    return 'c_${now}_$random';
  }

  Future<bool> sendMessage(
    String receiverId,
    String text, {
    String? reelId,
    String? postId,
    String? postImageUrl,
    String? postCaption,
    String? postOwnerUsername,
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
        'This conversation has an invalid user.',
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

    final clientMessageId = _generateClientMessageId();

    final payload = <String, dynamic>{
      'receiverId': parsedReceiverId,
      'message': text,
      'messageType': messageType,
      'clientMessageId': clientMessageId,
      'createdAt': DateTime.now().toIso8601String(),
      'mediaUrl': ?mediaUrl,
      'reelId': ?reelId,
      'postId': ?postId,
      'postImageUrl': ?postImageUrl,
      'postCaption': ?postCaption,
      'postOwnerUsername': ?postOwnerUsername,
    };

    final optimisticMsg = MessageModel(
      id: 'local-$clientMessageId',
      clientMessageId: clientMessageId,
      senderId: myId,
      receiverId: receiverId,
      message: text,
      messageType: messageType,
      mediaUrl: mediaUrl,
      reelId: reelId,
      postId: postId,
      postImageUrl: postImageUrl,
      postCaption: postCaption,
      postOwnerUsername: postOwnerUsername,
      createdAt: DateTime.now(),
      isRead: false,
      isPersisted: false,
      isPending: true,
      sendError: false,
    );

    _pendingOutbox.add(payload);
    await _persistPendingOutbox();

    if (activeChatUserId == receiverId) {
      _upsertMessage(optimisticMsg);
      _saveConversationCache(receiverId);
    }

    _updateConversationForIncomingMessage(optimisticMsg);

    if (!_chatSocket.isConnected) {
      _chatSocket.connect();
      return true;
    }

    return _deliverPendingMessage(payload, optimisticMsg);
  }

  Future<bool> retryMessage(MessageModel msg) async {
    final clientMsgId = msg.clientMessageId;
    if (clientMsgId == null) return false;

    final index = messages.indexWhere(
      (m) => m.clientMessageId == clientMsgId || m.id == msg.id,
    );
    if (index != -1) {
      messages[index] = messages[index].copyWith(
        isPending: true,
        sendError: false,
      );
    }

    final parsedReceiverId = int.tryParse(msg.receiverId) ?? msg.receiverId;

    final payload = <String, dynamic>{
      'receiverId': parsedReceiverId,
      'message': msg.message,
      'messageType': msg.messageType,
      'clientMessageId': clientMsgId,
      if (msg.mediaUrl != null) 'mediaUrl': msg.mediaUrl,
      if (msg.reelId != null) 'reelId': msg.reelId,
      if (msg.postId != null) 'postId': msg.postId,
      if (msg.postImageUrl != null) 'postImageUrl': msg.postImageUrl,
      if (msg.postCaption != null) 'postCaption': msg.postCaption,
      if (msg.postOwnerUsername != null)
        'postOwnerUsername': msg.postOwnerUsername,
    };

    if (!_chatSocket.isConnected) {
      await _chatSocket.connect();
    }

    return _deliverPendingMessage(payload, msg);
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
        Get.snackbar(
          'Photo not sent',
          'The server returned an invalid upload.',
        );
        return false;
      }
      return await sendMessage(
        receiverId,
        '',
        mediaUrl: data['mediaUrl'].toString(),
        messageTypeOverride: 'image',
      );
    } catch (error) {
      debugPrint('Error uploading chat image: $error');
      Get.snackbar('Photo not sent', 'Could not upload this photo.');
      return false;
    }
  }

  Future<bool> sendVoiceMessage(
    String receiverId,
    String filePath,
    int durationSeconds,
  ) async {
    try {
      final response = await _apiService.postMultipart(
        '${ApiConstants.messages}/upload',
        {'messageType': 'voice', 'duration': durationSeconds.toString()},
        'media',
        filePath,
      );
      final decoded = _decodeResponse(response.body);
      String mediaUrl = filePath;
      if (response.statusCode == 201 &&
          decoded?['success'] == true &&
          decoded?['data'] is Map) {
        final dataMap = decoded!['data'] as Map;
        mediaUrl = dataMap['mediaUrl']?.toString() ?? filePath;
      }

      return await sendMessage(
        receiverId,
        '🎤 Voice Note (${durationSeconds}s)',
        mediaUrl: mediaUrl,
        messageTypeOverride: 'voice',
      );
    } catch (error) {
      debugPrint('Error uploading voice note: $error');
      return await sendMessage(
        receiverId,
        '🎤 Voice Note (${durationSeconds}s)',
        mediaUrl: filePath,
        messageTypeOverride: 'voice',
      );
    }
  }

  Future<void> _flushPendingMessages() async {
    for (final item in List<Map<String, dynamic>>.from(_pendingOutbox)) {
      if (!_chatSocket.isConnected) return;
      await _deliverPendingMessage(item);
    }
  }

  Future<bool> _deliverPendingMessage(
    Map<String, dynamic> payload, [
    MessageModel? optimisticMsg,
  ]) async {
    final clientMessageId = payload['clientMessageId']?.toString();
    final response = await _chatSocket.sendMessage(payload);

    if (response == null ||
        response['success'] != true ||
        response['data'] is! Map) {
      if (clientMessageId != null) {
        final index = messages.indexWhere(
          (m) =>
              m.clientMessageId == clientMessageId ||
              m.id == 'local-$clientMessageId',
        );
        if (index != -1) {
          messages[index] = messages[index].copyWith(
            isPending: false,
            sendError: true,
          );
        }
      }
      return false;
    }

    final message = MessageModel.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );

    _pendingOutbox.removeWhere(
      (item) => item['clientMessageId'] == clientMessageId,
    );
    await _persistPendingOutbox();

    if (activeChatUserId == message.receiverId ||
        activeChatUserId == message.senderId) {
      _upsertMessage(
        message.copyWith(isPending: false, sendError: false, isPersisted: true),
      );
      await _saveConversationCache(message.receiverId);
    }
    fetchConversations();
    return true;
  }

  Future<bool> unsendMessage(MessageModel msg) async {
    try {
      final msgId = msg.id;
      final clientMsgId = msg.clientMessageId;

      // 1. Remove locally immediately for optimistic response
      messages.removeWhere(
        (m) =>
            (msgId.isNotEmpty && m.id == msgId) ||
            (clientMsgId != null &&
                clientMsgId.isNotEmpty &&
                m.clientMessageId == clientMsgId),
      );

      // 2. Remove from pending outbox if pending
      if (clientMsgId != null) {
        _pendingOutbox.removeWhere(
          (item) => item['clientMessageId'] == clientMsgId,
        );
        await _persistPendingOutbox();
      }

      if (activeChatUserId != null) {
        await _saveConversationCache(activeChatUserId!);
      }
      fetchConversations();

      // 3. Emit socket event and call REST API if persisted
      if (msg.isPersisted && msgId.isNotEmpty && !msgId.startsWith('local-')) {
        _chatSocket.unsendMessage(msgId, msg.receiverId);
        try {
          final response = await _apiService.delete(
            '${ApiConstants.messages}/$msgId',
          );
          debugPrint('[CHAT] Unsend message response: ${response.statusCode}');
        } catch (e) {
          debugPrint('[CHAT] Unsend API call exception (socket sent): $e');
        }
      }

      Get.snackbar(
        'Message Unsent',
        'Message was unsent.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (e) {
      debugPrint("Error unsending message: $e");
      Get.snackbar('Error', 'Could not unsend message');
      return false;
    }
  }

  Future<bool> deleteMessageLocally(MessageModel msg) async {
    final msgId = msg.id;
    final clientMsgId = msg.clientMessageId;

    messages.removeWhere(
      (m) =>
          (msgId.isNotEmpty && m.id == msgId) ||
          (clientMsgId != null &&
              clientMsgId.isNotEmpty &&
              m.clientMessageId == clientMsgId),
    );

    if (activeChatUserId != null) {
      await _saveConversationCache(activeChatUserId!);
    }
    fetchConversations();

    Get.snackbar(
      'Deleted',
      'Message removed from your chat',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
    return true;
  }
}
