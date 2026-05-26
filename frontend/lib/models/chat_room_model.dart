class ChatRoomModel {
  final String    userId;
  final String    username;
  final String    latestMessage;
  final DateTime? latestMessageTime;
  final int       unreadCount;
  final String?   latestMessageStatus;
  final bool      isOnline;

  ChatRoomModel({
    required this.userId,
    required this.username,
    required this.latestMessage,
    this.latestMessageTime,
    this.unreadCount = 0,
    this.latestMessageStatus,
    this.isOnline = false,
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      userId:              map['userId']?.toString()  ?? '',
      username:            map['username']?.toString() ?? '',
      latestMessage:       map['latestMessage']?.toString() ?? '',
      latestMessageTime:   map['latestMessageTime'] != null
          ? DateTime.tryParse(map['latestMessageTime'].toString())
          : null,
      unreadCount:         (map['unreadCount'] as num?)?.toInt() ?? 0,
      latestMessageStatus: map['latestMessageStatus']?.toString(),
      isOnline:            map['isOnline'] == true,
    );
  }
}
