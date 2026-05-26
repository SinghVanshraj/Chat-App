import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class AuthService {
  static Future<Map<String, dynamic>> registerUser(
      String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${Config.apiUrl}/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201 &&
          data['userId'] != null &&
          data['token']  != null) {
        await _save(data['userId'].toString(), data['token'].toString());
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> loginUser(
      String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${Config.apiUrl}/api/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 &&
          data['userId'] != null &&
          data['token']  != null) {
        await _save(data['userId'].toString(), data['token'].toString());
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> _save(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('token',  token);
  }

  static Future<bool>    isLoggedIn() async =>
      (await SharedPreferences.getInstance()).getString('userId') != null;

  static Future<String?> getUserId() async =>
      (await SharedPreferences.getInstance()).getString('userId');

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString('token');

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
