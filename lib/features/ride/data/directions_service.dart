import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DirectionsService {
  DirectionsService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  final Dio _dio;

  static const String _baseUrl =
      'https://avuxo-backend-production.up.railway.app';

  Future<Map<String, dynamic>?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/directions',
        queryParameters: {
          'originLat': originLat,
          'originLng': originLng,
          'destLat': destLat,
          'destLng': destLng,
        },
      );

      final data = response.data;

      debugPrint('BACKEND DIRECTIONS: $data');

      if (data == null) {
        return null;
      }

      if (data['status'] != 'OK') {
        debugPrint(
          'ERRO BACKEND DIRECTIONS: ${data['error_message']}',
        );
        return null;
      }

      final polyline = data['polyline'];
      final distance = data['distance'];
      final duration = data['duration'];

      if (polyline == null ||
          distance == null ||
          duration == null) {
        debugPrint(
          'DIRECTIONS INVÁLIDO: campos obrigatórios ausentes',
        );
        return null;
      }

      return {
        'polyline': polyline,
        'distance': distance,
        'duration': duration,
      };
    } on DioException catch (e) {
      debugPrint(
        'ERRO DIRECTIONS DIO: ${e.message}',
      );
      return null;
    } catch (e) {
      debugPrint(
        'ERRO AO CHAMAR DIRECTIONS: $e',
      );
      return null;
    }
  }
}