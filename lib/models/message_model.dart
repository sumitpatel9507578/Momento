class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType;
  final String? reelId;
  final String? reelVideoUrl;
  final String? reelCaption;
  final String? reelOwnerUsername;
  final String? conversationUserId;
  final String? conversationUsername;
  final String? conversationName;
  final String? conversationProfileImage;
  final DateTime createdAt;
  final bool isRead;
  final bool isSaved;
  final bool isPersisted;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
    this.reelId,
    this.reelVideoUrl,
    this.reelCaption,
    this.reelOwnerUsername,
    this.conversationUserId,
    this.conversationUsername,
    this.conversationName,
    this.conversationProfileImage,
    required this.createdAt,
    required this.isRead,
    this.isSaved = false,
    this.isPersisted = true,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] is Map
        ? json['sender']['id'] ?? json['sender']['uid']
        : json['sender'];
    final receiver = json['receiver'] is Map
        ? json['receiver']['id'] ?? json['receiver']['uid']
        : json['receiver'];

    return MessageModel(
      id:
          (json['id'] ??
                  json['itemId'] ??
                  json['_id'] ??
                  json['messageId'] ??
                  json['message_id'] ??
                  '')
              .toString(),
      senderId: (json['senderId'] ?? json['sender_id'] ?? sender ?? '')
          .toString(),
      receiverId:
          (json['receiverId'] ??
                  json['receiver_id'] ??
                  json['recipientId'] ??
                  receiver ??
                  '')
              .toString(),
      message: (json['message'] ?? json['text'] ?? json['content'] ?? '')
          .toString(),
      messageType: (json['messageType'] ?? json['message_type'] ?? 'text')
          .toString(),
      reelId: (json['reelId'] ?? json['reel_id']) == null
          ? null
          : (json['reelId'] ?? json['reel_id']).toString(),
      reelVideoUrl: (json['reelVideoUrl'] ?? json['reel_video_url'])
          ?.toString(),
      reelCaption: (json['reelCaption'] ?? json['reel_caption'])?.toString(),
      reelOwnerUsername:
          (json['reelOwnerUsername'] ?? json['reel_owner_username'])
              ?.toString(),
      conversationUserId:
          (json['conversationUserId'] ?? json['conversation_user_id'])
              ?.toString(),
      conversationUsername:
          (json['conversationUsername'] ?? json['conversation_username'])
              ?.toString(),
      conversationName: (json['conversationName'] ?? json['conversation_name'])
          ?.toString(),
      conversationProfileImage:
          (json['conversationProfileImage'] ??
                  json['conversation_profile_image'])
              ?.toString(),
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.tryParse(
                  (json['createdAt'] ?? json['created_at']).toString(),
                ) ??
                DateTime.now()
          : DateTime.now(),
      isRead:
          json['isRead'] == true ||
          json['is_read'] == 1 ||
          json['is_read'] == true,
      isSaved:
          json['itemType'] == 'message' ||
          json['isSaved'] == true ||
          json['is_saved'] == 1 ||
          json['is_saved'] == true ||
          json['saved'] == true,
      isPersisted:
          ((json['id'] ??
                  json['itemId'] ??
                  json['_id'] ??
                  json['messageId'] ??
                  json['message_id'])
              ?.toString()
              .isNotEmpty ??
          false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
      'reel_id': reelId,
      'reel_video_url': reelVideoUrl,
      'reel_caption': reelCaption,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'is_saved': isSaved,
      'is_persisted': isPersisted,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    String? messageType,
    String? reelId,
    String? reelVideoUrl,
    String? reelCaption,
    String? reelOwnerUsername,
    String? conversationUserId,
    String? conversationUsername,
    String? conversationName,
    String? conversationProfileImage,
    DateTime? createdAt,
    bool? isRead,
    bool? isSaved,
    bool? isPersisted,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      reelId: reelId ?? this.reelId,
      reelVideoUrl: reelVideoUrl ?? this.reelVideoUrl,
      reelCaption: reelCaption ?? this.reelCaption,
      reelOwnerUsername: reelOwnerUsername ?? this.reelOwnerUsername,
      conversationUserId: conversationUserId ?? this.conversationUserId,
      conversationUsername: conversationUsername ?? this.conversationUsername,
      conversationName: conversationName ?? this.conversationName,
      conversationProfileImage:
          conversationProfileImage ?? this.conversationProfileImage,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isSaved: isSaved ?? this.isSaved,
      isPersisted: isPersisted ?? this.isPersisted,
    );
  }
}
