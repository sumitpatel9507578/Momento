import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../services/api_service.dart';
import '../utils/api_constants.dart';

class ChatSocketService {
  ChatSocketService({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;
  IO.Socket? _socket;

  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(String message)? onConnectionError;
  void Function(Map<String, dynamic> message)? onMessage;
  void Function(Map<String, dynamic> update)? onTyping;
  void Function(Map<String, dynamic> update)? onRead;
  void Function(Map<String, dynamic> update)? onPresenceUpdate;
  void Function(List<String> userIds)? onPresenceSnapshot;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      onConnectionError?.call('Please sign in again to use chat.');
      return;
    }

    _socket?.dispose();
    final socket = IO.io(
      ApiConstants.serverUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token},
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
      },
    );
    _socket = socket;

    socket.onConnect((_) => onConnected?.call());
    socket.onDisconnect((_) => onDisconnected?.call());
    socket.onConnectError((error) {
      final message = error is Map
          ? error['message']?.toString()
          : error?.toString();
      onConnectionError?.call(
        message == 'ACCOUNT_NOT_FOUND'
            ? 'Your account is not available on this server. Sign in again.'
            : 'Chat connection failed. Messages will retry when connected.',
      );
    });
    socket.on('chat:message', (dynamic data) {
      if (data is Map) onMessage?.call(Map<String, dynamic>.from(data));
    });
    socket.on('chat:typing', (dynamic data) {
      if (data is Map) onTyping?.call(Map<String, dynamic>.from(data));
    });
    socket.on('chat:read', (dynamic data) {
      if (data is Map) onRead?.call(Map<String, dynamic>.from(data));
    });
    socket.on('presence:update', (dynamic data) {
      if (data is Map) onPresenceUpdate?.call(Map<String, dynamic>.from(data));
    });
    socket.on('presence:snapshot', (dynamic data) {
      if (data is List) {
        onPresenceSnapshot?.call(data.map((id) => id.toString()).toList());
      }
    });

    socket.connect();
  }

  Future<Map<String, dynamic>?> sendMessage(
    Map<String, dynamic> payload,
  ) async {
    final socket = _socket;
    if (socket == null || !socket.connected) return null;

    final completer = Completer<Map<String, dynamic>?>();
    socket.emitWithAck(
      'chat:send',
      payload,
      ack: (dynamic response) {
        if (completer.isCompleted) return;
        completer.complete(
          response is Map ? Map<String, dynamic>.from(response) : null,
        );
      },
    );
    try {
      return await completer.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      return null;
    }
  }

  void joinConversation(String userId) {
    _socket?.emitWithAck('chat:join', {'userId': userId});
  }

  void setTyping(String receiverId, bool isTyping) {
    _socket?.emit('chat:typing', {
      'receiverId': receiverId,
      'isTyping': isTyping,
    });
  }

  void markRead(String senderId) {
    _socket?.emit('chat:read', {'senderId': senderId});
  }

  void emitPresenceOnline() {
    _socket?.emit('presence:online');
  }

  void emitPresenceOffline() {
    _socket?.emit('presence:offline');
  }

  void emitPing() {
    _socket?.emit('presence:ping');
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
