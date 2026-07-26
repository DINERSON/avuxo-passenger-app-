import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PassengerRideService {
  PassengerRideService({
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

  Map<String, dynamic>? _decodeMap(String body) {
    try {
      final data = jsonDecode(body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> requestRide({
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ride/request'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 12),
          );

      final data = _decodeMap(response.body);

      if (data != null) {
        return data;
      }

      return {
        'success': false,
        'message': 'Resposta inválida do backend.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Erro de conexão com o backend.',
      };
    }
  }

  Future<Map<String, dynamic>?> getCurrentRide({
    String? rideId,
  }) async {
    try {
      final cleanRideId = rideId?.trim();

      final uri = Uri.parse('$baseUrl/ride/current').replace(
        queryParameters: {
          if (cleanRideId != null && cleanRideId.isNotEmpty)
            'rideId': cleanRideId,
        },
      );

      final response = await http
          .get(
            uri,
            headers: await _headers(),
          )
          .timeout(
            const Duration(seconds: 7),
          );

      if (response.statusCode != 200) {
        return null;
      }

      return _decodeMap(response.body);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRideById(
    String rideId,
  ) async {
    final id = rideId.trim();

    if (id.isEmpty) return null;

    return getCurrentRide(
      rideId: id,
    );
  }

  Future<bool> cancelRide({
    required String rideId,
    String reason = 'Cancelada pelo passageiro',
  }) async {
    final id = rideId.trim();

    if (id.isEmpty) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ride/cancel'),
            headers: await _headers(),
            body: jsonEncode({
              'rideId': id,
              'id': id,
              'reason': reason,
              'cancelledBy': 'passenger',
              'canceledBy': 'passenger',
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

  Future<Map<String, dynamic>?> sendChatMessage({
    required String rideId,
    required String text,
  }) async {
    final id = rideId.trim();
    final clean = text.trim();

    if (id.isEmpty || clean.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat/send'),
            headers: await _headers(),
            body: jsonEncode({
              'rideId': id,
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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      return _decodeMap(response.body);
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getChatMessages({
    required String rideId,
  }) async {
    final id = rideId.trim();

    if (id.isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/chat/current').replace(
        queryParameters: {
          'rideId': id,
        },
      );

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

      final data = _decodeMap(response.body);

      if (data == null) return [];

      final chat = data['chat'] ?? data['messages'] ?? data['data'];

      if (chat is List) {
        return chat;
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRideHistory({
    String? passengerId,
  }) async {
    try {
      final cleanPassengerId = passengerId?.trim();

      final uri = Uri.parse('$baseUrl/ride/history').replace(
        queryParameters: {
          if (cleanPassengerId != null && cleanPassengerId.isNotEmpty)
            'passengerId': cleanPassengerId,
        },
      );

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

      final data = _decodeMap(response.body);

      if (data == null) return [];

      final rides = data['rides'] ?? data['history'] ?? data['data'];

      if (rides is! List) {
        return [];
      }

      return rides
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> submitReview({
    required String rideId,
    required double rating,
    required String comment,
  }) async {
    final id = rideId.trim();
    if (id.isEmpty || rating < 1 || rating > 5) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ride/review'),
            headers: await _headers(),
            body: jsonEncode({
              'rideId': id,
              'rating': rating,
              'comment': comment.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
