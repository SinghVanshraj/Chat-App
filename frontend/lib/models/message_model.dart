class MessageModel {
  final String   messageId;
  final String   chatRoomId;
  final String   senderId;
  final String   receiverId;
  final String   message;
  final String   status;   
  final DateTime createdAt;
  final bool     isMine;

  MessageModel({
    required this.messageId,
    required this.chatRoomId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.isMine,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String currentUserId) {
    final sender = map['sender']?.toString() ?? '';
    return MessageModel(
      messageId:  map['messageId']?.toString()  ?? map['_id']?.toString() ?? '',
      chatRoomId: map['chatRoomId']?.toString() ?? '',
      senderId:   sender,
      receiverId: map['receiver']?.toString()   ?? '',
      message:    map['message']?.toString()    ?? '',
      status:     map['status']?.toString()     ?? 'sent',
      createdAt:  map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isMine: map['isMine'] ?? (sender == currentUserId),
    );
  }

  MessageModel copyWith({String? messageId, String? status}) => MessageModel(
        messageId:  messageId ?? this.messageId,
        chatRoomId: chatRoomId,
        senderId:   senderId,
        receiverId: receiverId,
        message:    message,
        status:     status ?? this.status,
        createdAt:  createdAt,
        isMine:     isMine,
      );
}
