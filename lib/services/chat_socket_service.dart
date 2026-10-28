import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../services/api_service.dart';
import '../utils/api_constants.dart';

class ChatSocketService extends GetxService {
  ChatSocketService({required this._apiService});

  final ApiService _apiService;
  IO.Socket? _socket;

  final onlineUserIds = <String>{}.obs;

  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(String message)? onConnectionError;
  void Function(Map<String, dynamic> message)? onMessage;
  void Function(Map<String, dynamic> update)? onTyping;
  void Function(Map<String, dynamic> update)? onRead;
  void Function(Map<String, dynamic> update)? onMessageUnsent;
  void Function(Map<String, dynamic> update)? onPresenceUpdate;
  void Function(List<String> userIds)? onPresenceSnapshot;

  void Function(Map<String, dynamic> data)? onCommentAdded;
  void Function(Map<String, dynamic> data)? onCommentLiked;
  void Function(Map<String, dynamic> data)? onCommentDeleted;

  bool get isConnected => _socket?.connected == true;

  bool isUserOnline(dynamic userId) {
    if (userId == null) return false;
    final strId = userId.toString();
    return onlineUserIds.contains(strId);
  }

  String? _parseUserIdString(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final raw =
          data['userId'] ?? data['user_id'] ?? data['id'] ?? data['uid'];
      return raw?.toString();
    }
    return data.toString();
  }

  Future<void> connect() async {
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[SOCKET] No JWT token available for socket connection.');
      onConnectionError?.call('Please sign in again to use chat.');
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('[SOCKET] Already connected (socket id: ${_socket!.id})');
      return;
    }

    _socket?.dispose();

    debugPrint(
      '[SOCKET] Creating socket connection to ${ApiConstants.serverUrl}...',
    );
    final socket = IO.io(ApiConstants.serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
    });
    _socket = socket;

    // REGISTER ALL LISTENERS BEFORE CALLING CONNECT()
    socket.onConnect((_) {
      debugPrint('[SOCKET] Connected to server (id: ${socket.id})');
      onConnected?.call();
    });

    socket.onDisconnect((reason) {
      debugPrint('[SOCKET] Disconnected from server: $reason');
      onDisconnected?.call();
    });

    socket.onConnectError((error) async {
      debugPrint('[SOCKET] Connect error: $error');
      final message = error is Map
          ? error['message']?.toString()
          : error?.toString();

      if (message != null &&
          (message.contains('Unauthorized') ||
              message.contains('jwt expired') ||
              message.contains('invalid token') ||
              message == 'ACCOUNT_NOT_FOUND')) {
        debugPrint(
          '[SOCKET] Auth error encountered: $message. Redirecting to login.',
        );
        await _apiService.deleteToken();
        if (Get.currentRoute != '/login') {
          Get.offAllNamed('/login');
        }
      }

      onConnectionError?.call(
        message == 'ACCOUNT_NOT_FOUND'
            ? 'Your account is not available on this server. Sign in again.'
            : 'Chat connection failed. Messages will retry when connected.',
      );
    });

    socket.onError((error) {
      debugPrint('[SOCKET] Socket error: $error');
    });

    socket.on('chat:message', (dynamic data) {
      debugPrint('[SOCKET] Received chat:message: $data');
      if (data is Map) onMessage?.call(Map<String, dynamic>.from(data));
    });

    socket.on('chat:typing', (dynamic data) {
      debugPrint('[SOCKET] Received chat:typing: $data');
      if (data is Map) onTyping?.call(Map<String, dynamic>.from(data));
    });

    socket.on('chat:read', (dynamic data) {
      debugPrint('[SOCKET] Received chat:read: $data');
      if (data is Map) onRead?.call(Map<String, dynamic>.from(data));
    });

    socket.on('chat:unsend', (dynamic data) {
      debugPrint('[SOCKET] Received chat:unsend: $data');
      if (data is Map) onMessageUnsent?.call(Map<String, dynamic>.from(data));
    });

    socket.on('chat:deleted', (dynamic data) {
      debugPrint('[SOCKET] Received chat:deleted: $data');
      if (data is Map) onMessageUnsent?.call(Map<String, dynamic>.from(data));
    });

    socket.on('presence:snapshot', (dynamic data) {
      debugPrint('[SOCKET] Received presence:snapshot: $data');
      if (data is List) {
        final parsed = <String>{};
        for (final item in data) {
          if (item != null) parsed.add(item.toString());
        }
        onlineUserIds.assignAll(parsed);
        onPresenceSnapshot?.call(parsed.toList());
      }
    });

    socket.on('presence:online', (dynamic data) {
      debugPrint('[SOCKET] Received presence:online: $data');
      final idStr = _parseUserIdString(data);
      if (idStr != null && idStr.isNotEmpty) {
        onlineUserIds.add(idStr);
      }
      if (data is Map) onPresenceUpdate?.call(Map<String, dynamic>.from(data));
    });

    socket.on('presence:offline', (dynamic data) {
      debugPrint('[SOCKET] Received presence:offline: $data');
      final idStr = _parseUserIdString(data);
      if (idStr != null && idStr.isNotEmpty) {
        onlineUserIds.remove(idStr);
      }
      if (data is Map) onPresenceUpdate?.call(Map<String, dynamic>.from(data));
    });

    socket.on('presence:update', (dynamic data) {
      debugPrint('[SOCKET] Received presence:update: $data');
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        final rawId = mapData['userId'] ?? mapData['user_id'];
        final idStr = _parseUserIdString(rawId);
        final isOnline =
            mapData['isOnline'] == true || mapData['is_online'] == true;
        if (idStr != null && idStr.isNotEmpty) {
          if (isOnline) {
            onlineUserIds.add(idStr);
          } else {
            onlineUserIds.remove(idStr);
          }
        }
        onPresenceUpdate?.call(mapData);
      }
    });

    socket.on('comment_added', (dynamic data) {
      debugPrint('[SOCKET] Received comment_added: $data');
      if (data is Map) onCommentAdded?.call(Map<String, dynamic>.from(data));
    });

    socket.on('comment_liked', (dynamic data) {
      debugPrint('[SOCKET] Received comment_liked: $data');
      if (data is Map) onCommentLiked?.call(Map<String, dynamic>.from(data));
    });

    socket.on('comment_deleted', (dynamic data) {
      debugPrint('[SOCKET] Received comment_deleted: $data');
      if (data is Map) onCommentDeleted?.call(Map<String, dynamic>.from(data));
    });

    debugPrint('[SOCKET] Calling socket.connect()...');
    socket.connect();
  }

  Future<Map<String, dynamic>?> sendMessage(
    Map<String, dynamic> payload,
  ) async {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      debugPrint('[SOCKET] Cannot send message, socket is disconnected');
      return null;
    }

    final completer = Completer<Map<String, dynamic>?>();
    debugPrint('[SOCKET] Emitting chat:send: $payload');
    socket.emitWithAck(
      'chat:send',
      payload,
      ack: (dynamic response) {
        debugPrint('[SOCKET] Received ack for chat:send: $response');
        if (completer.isCompleted) return;
        completer.complete(
          response is Map ? Map<String, dynamic>.from(response) : null,
        );
      },
    );

    try {
      return await completer.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      debugPrint('[SOCKET] Timeout waiting for chat:send ack (8s)');
      return null;
    }
  }

  void joinConversation(String userId) {
    final parsedId = int.tryParse(userId) ?? userId;
    final payload = {'userId': parsedId};
    debugPrint('[SOCKET] Emitting chat:join: $payload');
    _socket?.emitWithAck('chat:join', payload);
  }

  void joinPostRoom(String postId) {
    final payload = {'postId': postId};
    debugPrint('[SOCKET] Emitting comment:join: $payload');
    _socket?.emit('comment:join', payload);
  }

  void leavePostRoom(String postId) {
    final payload = {'postId': postId};
    debugPrint('[SOCKET] Emitting comment:leave: $payload');
    _socket?.emit('comment:leave', payload);
  }

  void setTyping(String receiverId, bool isTyping) {
    final parsedId = int.tryParse(receiverId) ?? receiverId;
    final payload = {'receiverId': parsedId, 'isTyping': isTyping};
    debugPrint('[SOCKET] Emitting chat:typing: $payload');
    _socket?.emit('chat:typing', payload);
  }

  void markRead(String senderId) {
    final parsedId = int.tryParse(senderId) ?? senderId;
    final payload = {'senderId': parsedId};
    debugPrint('[SOCKET] Emitting chat:read: $payload');
    _socket?.emit('chat:read', payload);
  }

  void unsendMessage(String messageId, String receiverId) {
    final parsedMsgId = int.tryParse(messageId) ?? messageId;
    final parsedReceiverId = int.tryParse(receiverId) ?? receiverId;
    final payload = {
      'messageId': parsedMsgId,
      'id': parsedMsgId,
      'receiverId': parsedReceiverId,
    };
    debugPrint('[SOCKET] Emitting chat:unsend: $payload');
    _socket?.emit('chat:unsend', payload);
  }

  void emitPresenceOnline() {
    debugPrint('[SOCKET] Emitting presence:online');
    _socket?.emit('presence:online');
  }

  void emitPresenceOffline() {
    debugPrint('[SOCKET] Emitting presence:offline');
    _socket?.emit('presence:offline');
  }

  void emitPing() {
    debugPrint('[SOCKET] Emitting presence:ping');
    _socket?.emit('presence:ping');
  }

  IO.Socket? get socket => _socket;

  void initiateCall(Map<String, dynamic> payload) {
    debugPrint('[SOCKET] Emitting call:initiate: $payload');
    _socket?.emit('call:initiate', payload);
  }

  void acceptCall(String callerId, Map<String, dynamic> answer) {
    final payload = {'callerId': callerId, 'answer': answer};
    debugPrint('[SOCKET] Emitting call:accept: $payload');
    _socket?.emit('call:accept', payload);
  }

  void rejectCall(String callerId) {
    final payload = {'callerId': callerId};
    debugPrint('[SOCKET] Emitting call:reject: $payload');
    _socket?.emit('call:reject', payload);
  }

  void sendIceCandidate(String targetUserId, Map<String, dynamic> candidate) {
    final payload = {'targetUserId': targetUserId, 'candidate': candidate};
    debugPrint('[SOCKET] Emitting call:ice_candidate: $payload');
    _socket?.emit('call:ice_candidate', payload);
  }

  void endCall(String targetUserId) {
    final payload = {'targetUserId': targetUserId};
    debugPrint('[SOCKET] Emitting call:end: $payload');
    _socket?.emit('call:end', payload);
  }

  void disconnect() {
    debugPrint('[SOCKET] Disconnecting socket...');
    _socket?.dispose();
    _socket = null;
  }
}
