import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import 'auth_service.dart';

class ChatService {
  static Future<List<ChatRoomModel>> fetchChatRooms() async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http.get(
        Uri.parse('${Config.apiUrl}/api/chat/chat-room'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .map((e) => ChatRoomModel.fromMap(e))
            .toList();
      }
      return [];
    } catch (_) { return []; }
  }

  static Future<List<MessageModel>> fetchMessages({
    required String receiverId,
    int    page       = 1,
    int    limit      = 20,
    String searchText = '',
  }) async {
    try {
      final headers = await AuthService.authHeaders();
      final userId  = await AuthService.getUserId() ?? '';

      final params = <String, String>{
        'senderId':   userId,       // current user is the sender side
        'receiverId': receiverId,
        'page':       '$page',
        'limit':      '$limit',
        if (searchText.isNotEmpty) 'searchText': searchText,
      };

      final uri = Uri.parse('${Config.apiUrl}/api/chat/messages')
          .replace(queryParameters: params);

      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .map((e) => MessageModel.fromMap(e, userId))
            .toList();
      }
      return [];
    } catch (_) { return []; }
  }

  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final headers = await AuthService.authHeaders();
      final res = await http.get(
        Uri.parse('${Config.apiUrl}/api/users/users'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) { return []; }
  }
}
