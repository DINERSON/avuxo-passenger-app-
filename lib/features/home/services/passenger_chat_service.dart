import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PassengerChatService {
  PassengerChatService({
    required this.baseUrl,
  });

  final String baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Sessão Firebase inválida.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };
  }

  Future<List<Map<String, dynamic>>> loadChat({
    String? rideId,
  }) async {
    try {
      final cleanRideId = rideId?.trim();

      final uri = cleanRideId != null && cleanRideId.isNotEmpty
          ? Uri.parse('$baseUrl/chat/current').replace(
              queryParameters: {
                'rideId': cleanRideId,
              },
            )
          : Uri.parse('$baseUrl/chat/current');

      final response = await http
          .get(
            uri,
            headers: await _headers(),
          )
          .timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      dynamic chat;

      if (data is Map) {
        chat = data['chat'] ?? data['messages'] ?? data['data'];
      } else {
        chat = data;
      }

      if (chat is! List) {
        return [];
      }

      return chat
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item),
          )
          .where((item) {
        final text = '${item['message'] ?? item['text'] ?? item['body'] ?? ''}'
            .trim();

        return text.isNotEmpty;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> sendMessage(
    String text, {
    String? rideId,
  }) async {
    final clean = text.trim();
    final cleanRideId = rideId?.trim();

    if (clean.isEmpty) {
      return false;
    }

    if (cleanRideId == null || cleanRideId.isEmpty) {
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/send'),
            headers: await _headers(),
            body: jsonEncode({
              'rideId': cleanRideId,
              'sender': 'passenger',
              'from': 'passenger',
              'role': 'passenger',
              'message': clean,
              'text': clean,
              'createdAt': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(
            const Duration(seconds: 8),
          );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
