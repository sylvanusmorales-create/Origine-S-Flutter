import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ApiService {
  static Future<List<Conversation>> getConversations() async {
    final base = await Config.getBaseUrl();
    final res = await http.get(Uri.parse('$base/api/conversations'));
    final List data = jsonDecode(res.body);
    return data.map((e) => Conversation.fromJson(e)).toList();
  }

  static Future<Conversation> createConversation() async {
    final base = await Config.getBaseUrl();
    final res = await http.post(Uri.parse('$base/api/conversations'));
    return Conversation.fromJson(jsonDecode(res.body));
  }

  static Future<void> deleteConversation(int id) async {
    final base = await Config.getBaseUrl();
    await http.delete(Uri.parse('$base/api/conversations/$id'));
  }

  static Future<void> renameConversation(int id, String title) async {
    final base = await Config.getBaseUrl();
    await http.patch(
      Uri.parse('$base/api/conversations/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );
  }

  static Future<List<Message>> getMessages(int convId) async {
    final base = await Config.getBaseUrl();
    final res = await http.get(Uri.parse('$base/api/conversations/$convId/messages'));
    final List data = jsonDecode(res.body);
    return data.map((e) => Message.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> getMemory() async {
    final base = await Config.getBaseUrl();
    final res = await http.get(Uri.parse('$base/api/memory'));
    return jsonDecode(res.body);
  }

  static Future<bool> checkHealth() async {
    try {
      final base = await Config.getBaseUrl();
      final res = await http
          .get(Uri.parse('$base/api/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}