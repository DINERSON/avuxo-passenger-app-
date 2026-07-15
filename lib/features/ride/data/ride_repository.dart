import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/common_models.dart';
import '../domain/ride_models.dart';

class RideRepository {
  RideRepository({
    required ApiClient apiClient,
    required String placesApiKey,
  })  : _api = apiClient.instance,
        _placesApiKey = placesApiKey;

  final Dio _api;
  final String _placesApiKey;

  Dio get _googleDio => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final text = input.trim();

    if (_placesApiKey.isEmpty || text.length < 3) {
      return <PlaceSuggestion>[];
    }

    try {
      final response = await _googleDio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': text,
          'key': _placesApiKey,
          'language': 'pt-BR',
          'components': 'country:br',
        },
      );

      final data = response.data;

      if (data == null || data['status'] != 'OK') {
        debugPrint('Places autocomplete erro: ${data?['status']}');
        return <PlaceSuggestion>[];
      }

      final predictions =
          data['predictions'] as List<dynamic>? ?? <dynamic>[];

      return predictions
          .whereType<Map<String, dynamic>>()
          .map((e) {
            final formatting =
                e['structured_formatting'] as Map<String, dynamic>?;

            return PlaceSuggestion(
              placeId: e['place_id'] as String? ?? '',
              mainText: formatting?['main_text'] as String? ?? '',
              description: e['description'] as String? ?? '',
              secondaryText: formatting?['secondary_text'] as String?,
            );
          })
          .where((e) => e.placeId.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      debugPrint('Erro autocomplete Dio: ${e.message}');
      return <PlaceSuggestion>[];
    } catch (e) {
      debugPrint('Erro autocomplete: $e');
      return <PlaceSuggestion>[];
    }
  }

  Future<Coordinate> placeDetails(String placeId) async {
    if (_placesApiKey.isEmpty) {
      throw AppException('Chave do Google Places ausente');
    }

    if (placeId.trim().isEmpty) {
      throw AppException('Destino inválido');
    }

    try {
      final response = await _googleDio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'geometry/location,formatted_address',
          'key': _placesApiKey,
          'language': 'pt-BR',
        },
      );

      final data = response.data;

      if (data == null || data['status'] != 'OK') {
        throw AppException('Não foi possível carregar o endereço');
      }

      final result = data['result'] as Map<String, dynamic>?;
      final geometry = result?['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;

      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();

      if (lat == null || lng == null || lat == 0 || lng == 0) {
        throw AppException('Localização do destino inválida');
      }

      return Coordinate(
        lat: lat,
        lng: lng,
        address: result?['formatted_address'] as String?,
      );
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      debugPrint('Erro placeDetails Dio: ${e.message}');
      throw AppException('Erro ao buscar destino');
    } catch (e) {
      debugPrint('Erro placeDetails: $e');
      throw AppException('Erro ao buscar destino');
    }
  }

  Future<List<LatLng>> routePreview({
    required Coordinate from,
    required Coordinate to,
  }) async {
    if (_isInvalidCoordinate(from) || _isInvalidCoordinate(to)) {
      return <LatLng>[];
    }

    if (_placesApiKey.isEmpty) {
      return <LatLng>[
        LatLng(from.lat, from.lng),
        LatLng(to.lat, to.lng),
      ];
    }

    try {
      final response = await _googleDio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${from.lat},${from.lng}',
          'destination': '${to.lat},${to.lng}',
          'key': _placesApiKey,
          'language': 'pt-BR',
          'mode': 'driving',
        },
      );

      final data = response.data;

      if (data == null || data['status'] != 'OK') {
        debugPrint('Directions erro: ${data?['status']}');

        return <LatLng>[
          LatLng(from.lat, from.lng),
          LatLng(to.lat, to.lng),
        ];
      }

      final routes = data['routes'] as List<dynamic>? ?? <dynamic>[];

      if (routes.isEmpty) {
        return <LatLng>[
          LatLng(from.lat, from.lng),
          LatLng(to.lat, to.lng),
        ];
      }

      final firstRoute = routes.first as Map<String, dynamic>?;
      final overview = firstRoute?['overview_polyline'] as Map<String, dynamic>?;
      final points = overview?['points'] as String? ?? '';

      if (points.isEmpty) {
        return <LatLng>[
          LatLng(from.lat, from.lng),
          LatLng(to.lat, to.lng),
        ];
      }

      final decoded = _decodePolyline(points);

      if (decoded.isEmpty) {
        return <LatLng>[
          LatLng(from.lat, from.lng),
          LatLng(to.lat, to.lng),
        ];
      }

      return decoded;
    } on DioException catch (e) {
      debugPrint('Erro routePreview Dio: ${e.message}');

      return <LatLng>[
        LatLng(from.lat, from.lng),
        LatLng(to.lat, to.lng),
      ];
    } catch (e) {
      debugPrint('Erro routePreview: $e');

      return <LatLng>[
        LatLng(from.lat, from.lng),
        LatLng(to.lat, to.lng),
      ];
    }
  }

  Future<Ride> requestRide({
    required Coordinate pickup,
    required Coordinate destination,
  }) async {
    if (_isInvalidCoordinate(pickup)) {
      throw AppException('Local de embarque inválido');
    }

    if (_isInvalidCoordinate(destination)) {
      throw AppException('Destino inválido');
    }

    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/ride/request',
        data: {
          'pickup': pickup.toJson(),
          'destination': destination.toJson(),
          'pickupLat': pickup.lat,
          'pickupLng': pickup.lng,
          'destinationLat': destination.lat,
          'destinationLng': destination.lng,
          'originLat': pickup.lat,
          'originLng': pickup.lng,
          'destLat': destination.lat,
          'destLng': destination.lng,
        },
      );

      final data = _extractDataMap(response.data);
      final ride = Ride.fromJson(data);

      if (ride.id.isEmpty) {
        throw AppException('Corrida criada sem rideId');
      }

      return ride;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      debugPrint('Erro requestRide Dio: ${e.message}');
      throw AppException(
        _extractErrorMessage(e.response?.data) ?? 'Erro ao solicitar corrida',
      );
    } catch (e) {
      debugPrint('Erro requestRide: $e');
      throw AppException('Erro ao solicitar corrida');
    }
  }

  Future<Ride> getRideById(String rideId) async {
    final safeRideId = rideId.trim();

    if (safeRideId.isEmpty) {
      throw AppException('rideId vazio ao buscar corrida');
    }

    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/ride/$safeRideId',
      );

      final data = _extractDataMap(response.data);
      final ride = Ride.fromJson(data);

      if (ride.id.isEmpty) {
        throw AppException('Corrida retornou sem rideId');
      }

      return ride;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      debugPrint('Erro getRideById Dio: ${e.message}');
      throw AppException(
        _extractErrorMessage(e.response?.data) ?? 'Erro ao atualizar corrida',
      );
    } catch (e) {
      debugPrint('Erro getRideById: $e');
      throw AppException('Erro ao atualizar corrida');
    }
  }

  Stream<Ride> pollRideStatus(String rideId) async* {
    final safeRideId = rideId.trim();

    if (safeRideId.isEmpty) {
      throw AppException('rideId vazio no polling da corrida');
    }

    while (true) {
      final ride = await getRideById(safeRideId);
      yield ride;

      if (ride.status == RideStatus.completed ||
          ride.status == RideStatus.cancelled) {
        break;
      }

      await Future<void>.delayed(const Duration(seconds: 4));
    }
  }

  Future<RideHistoryPage> getRideHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/ride/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = _extractDataMap(response.data);
      return RideHistoryPage.fromJson(data);
    } on DioException catch (e) {
      debugPrint('Erro getRideHistory Dio: ${e.message}');
      throw AppException(
        _extractErrorMessage(e.response?.data) ?? 'Erro ao carregar histórico',
      );
    } catch (e) {
      debugPrint('Erro getRideHistory: $e');
      throw AppException('Erro ao carregar histórico');
    }
  }

  Future<void> submitRating({
    required String rideId,
    required int score,
    String? comment,
  }) async {
    final safeRideId = rideId.trim();

    if (safeRideId.isEmpty) {
      throw AppException('rideId vazio ao avaliar corrida');
    }

    if (score < 1 || score > 5) {
      throw AppException('Nota inválida');
    }

    try {
      await _api.post<Map<String, dynamic>>(
        '/ride/review',
        data: {
          'rideId': safeRideId,
          'id': safeRideId,
          'rating': score,
          'score': score,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );
    } on DioException catch (e) {
      debugPrint('Erro submitRating Dio: ${e.message}');
      throw AppException(
        _extractErrorMessage(e.response?.data) ?? 'Erro ao enviar avaliação',
      );
    } catch (e) {
      debugPrint('Erro submitRating: $e');
      throw AppException('Erro ao enviar avaliação');
    }
  }

  bool _isInvalidCoordinate(Coordinate coordinate) {
    return coordinate.lat == 0 ||
        coordinate.lng == 0 ||
        coordinate.lat < -90 ||
        coordinate.lat > 90 ||
        coordinate.lng < -180 ||
        coordinate.lng > 180;
  }

  Map<String, dynamic> _extractDataMap(Map<String, dynamic>? body) {
    if (body == null) {
      return <String, dynamic>{};
    }

    final data = body['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    final ride = body['ride'];

    if (ride is Map<String, dynamic>) {
      return ride;
    }

    if (ride is Map) {
      return Map<String, dynamic>.from(ride);
    }

    final review = body['review'];

    if (review is Map<String, dynamic>) {
      return review;
    }

    if (review is Map) {
      return Map<String, dynamic>.from(review);
    }

    return body;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = <LatLng>[];

    if (encoded.isEmpty) {
      return poly;
    }

    int index = 0;
    int lat = 0;
    int lng = 0;

    try {
      while (index < encoded.length) {
        int b;
        int shift = 0;
        int result = 0;

        do {
          if (index >= encoded.length) {
            return poly;
          }
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        final dLat =
            (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

        lat += dLat;
        shift = 0;
        result = 0;

        do {
          if (index >= encoded.length) {
            return poly;
          }
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        final dLng =
            (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

        lng += dLng;

        poly.add(
          LatLng(
            lat / 1E5,
            lng / 1E5,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro decodePolyline: $e');
      return <LatLng>[];
    }

    return poly;
  }
}