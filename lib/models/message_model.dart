class MessageModel {
  final String id;
  final String? clientMessageId;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType;
  final String? mediaUrl;
  final String? reelId;
  final String? reelVideoUrl;
  final String? reelCaption;
  final String? reelOwnerUsername;
  final String? postId;
  final String? postImageUrl;
  final String? postCaption;
  final String? postOwnerUsername;
  final String? conversationUserId;
  final String? conversationUsername;
  final String? conversationName;
  final String? conversationProfileImage;
  final DateTime createdAt;
  final bool isRead;
  final bool isSaved;
  final bool isPersisted;
  final bool isPending;
  final bool sendError;

  MessageModel({
    required this.id,
    this.clientMessageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
    this.mediaUrl,
    this.reelId,
    this.reelVideoUrl,
    this.reelCaption,
    this.reelOwnerUsername,
    this.postId,
    this.postImageUrl,
    this.postCaption,
    this.postOwnerUsername,
    this.conversationUserId,
    this.conversationUsername,
    this.conversationName,
    this.conversationProfileImage,
    required this.createdAt,
    required this.isRead,
    this.isSaved = false,
    this.isPersisted = true,
    this.isPending = false,
    this.sendError = false,
  });

  bool get isPostShare =>
      messageType == 'post' && (postId != null && postId!.isNotEmpty);

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
      clientMessageId: (json['clientMessageId'] ?? json['client_message_id'])
          ?.toString(),
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
      mediaUrl: (json['mediaUrl'] ?? json['media_url'])?.toString(),
      reelId: (json['reelId'] ?? json['reel_id']) == null
          ? null
          : (json['reelId'] ?? json['reel_id']).toString(),
      reelVideoUrl: (json['reelVideoUrl'] ?? json['reel_video_url'])
          ?.toString(),
      reelCaption: (json['reelCaption'] ?? json['reel_caption'])?.toString(),
      reelOwnerUsername:
          (json['reelOwnerUsername'] ?? json['reel_owner_username'])
              ?.toString(),
      postId: (json['postId'] ?? json['post_id'] ?? json['itemId']) == null
          ? null
          : (json['postId'] ?? json['post_id'] ?? json['itemId']).toString(),
      postImageUrl:
          (json['postImageUrl'] ?? json['post_image_url'] ?? json['mediaUrl'])
              ?.toString(),
      postCaption: (json['postCaption'] ?? json['post_caption'])?.toString(),
      postOwnerUsername:
          (json['postOwnerUsername'] ?? json['post_owner_username'])
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
      createdAt: DateTime.parse(
        (json['createdAt'] ??
                json['created_at'] ??
                DateTime.now().toIso8601String())
            .toString(),
      ).toLocal(),
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
      isPersisted: json['isPersisted'] == false || json['is_persisted'] == false
          ? false
          : ((json['id'] ??
                        json['itemId'] ??
                        json['_id'] ??
                        json['messageId'] ??
                        json['message_id'])
                    ?.toString()
                    .isNotEmpty ??
                false),
      isPending: json['isPending'] == true || json['is_pending'] == true,
      sendError: json['sendError'] == true || json['send_error'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_message_id': clientMessageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
      'media_url': mediaUrl,
      'reel_id': reelId,
      'reel_video_url': reelVideoUrl,
      'reel_caption': reelCaption,
      'post_id': postId,
      'post_image_url': postImageUrl,
      'post_caption': postCaption,
      'post_owner_username': postOwnerUsername,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'is_saved': isSaved,
      'is_persisted': isPersisted,
      'is_pending': isPending,
      'send_error': sendError,
    };
  }

  MessageModel copyWith({
    String? id,
    String? clientMessageId,
    String? senderId,
    String? receiverId,
    String? message,
    String? messageType,
    String? mediaUrl,
    String? reelId,
    String? reelVideoUrl,
    String? reelCaption,
    String? reelOwnerUsername,
    String? postId,
    String? postImageUrl,
    String? postCaption,
    String? postOwnerUsername,
    String? conversationUserId,
    String? conversationUsername,
    String? conversationName,
    String? conversationProfileImage,
    DateTime? createdAt,
    bool? isRead,
    bool? isSaved,
    bool? isPersisted,
    bool? isPending,
    bool? sendError,
  }) {
    return MessageModel(
      id: id ?? this.id,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      reelId: reelId ?? this.reelId,
      reelVideoUrl: reelVideoUrl ?? this.reelVideoUrl,
      reelCaption: reelCaption ?? this.reelCaption,
      reelOwnerUsername: reelOwnerUsername ?? this.reelOwnerUsername,
      postId: postId ?? this.postId,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      postCaption: postCaption ?? this.postCaption,
      postOwnerUsername: postOwnerUsername ?? this.postOwnerUsername,
      conversationUserId: conversationUserId ?? this.conversationUserId,
      conversationUsername: conversationUsername ?? this.conversationUsername,
      conversationName: conversationName ?? this.conversationName,
      conversationProfileImage:
          conversationProfileImage ?? this.conversationProfileImage,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isSaved: isSaved ?? this.isSaved,
      isPersisted: isPersisted ?? this.isPersisted,
      isPending: isPending ?? this.isPending,
      sendError: sendError ?? this.sendError,
    );
  }
}
