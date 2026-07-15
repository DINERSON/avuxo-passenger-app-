import 'dart:convert';
import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PassengerMapsRoute {
  final List<LatLng> points;
  final double distanceKm;
  final String distanceText;
  final String eta;

  const PassengerMapsRoute({
    required this.points,
    required this.distanceKm,
    required this.distanceText,
    required this.eta,
  });
}

class PassengerPlaceSuggestion {
  final String placeId;
  final String title;
  final String subtitle;

  const PassengerPlaceSuggestion({
    required this.placeId,
    required this.title,
    required this.subtitle,
  });
}

class PassengerMapsService {
  PassengerMapsService({
    required this.googleApiKey,
  });

  final String googleApiKey;

  bool get _hasApiKey {
    return googleApiKey.trim().isNotEmpty;
  }

  Future<List<PassengerPlaceSuggestion>> searchPlaces(String input) async {
    final query = input.trim();

    if (query.length < 3 || !_hasApiKey) {
      return [];
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': query,
          'language': 'pt-BR',
          'components': 'country:br',
          'key': googleApiKey.trim(),
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 8),
          );

      final data = jsonDecode(response.body);

      if (data is! Map) {
        return [];
      }

      final status = data['status']?.toString() ?? '';

      if (status == 'ZERO_RESULTS') {
        return [];
      }

      if (status != 'OK' || data['predictions'] is! List) {
        return [];
      }

      final predictions = data['predictions'] as List;

      return predictions
          .whereType<Map>()
          .map((item) {
            final structured = item['structured_formatting'];

            String title = '';
            String subtitle = '';

            if (structured is Map) {
              title = structured['main_text']?.toString() ?? '';
              subtitle = structured['secondary_text']?.toString() ?? '';
            }

            if (title.trim().isEmpty) {
              title = item['description']?.toString() ?? 'Endereço';
            }

            return PassengerPlaceSuggestion(
              placeId: item['place_id']?.toString() ?? '',
              title: title.trim(),
              subtitle: subtitle.trim(),
            );
          })
          .where(
            (item) =>
                item.placeId.trim().isNotEmpty &&
                item.title.trim().isNotEmpty,
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<LatLng?> getPlaceLatLng(String placeId) async {
    final cleanPlaceId = placeId.trim();

    if (cleanPlaceId.isEmpty || !_hasApiKey) {
      return null;
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        {
          'place_id': cleanPlaceId,
          'fields': 'geometry',
          'language': 'pt-BR',
          'key': googleApiKey.trim(),
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 8),
          );

      final data = jsonDecode(response.body);

      if (data is! Map) {
        return null;
      }

      final status = data['status']?.toString() ?? '';

      if (status != 'OK') {
        return null;
      }

      final result = data['result'];

      if (result is! Map) {
        return null;
      }

      final geometry = result['geometry'];

      if (geometry is! Map) {
        return null;
      }

      final location = geometry['location'];

      if (location is! Map) {
        return null;
      }

      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        return null;
      }

      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  Future<String> getAddressFromLatLng(LatLng point) async {
    if (!_hasApiKey) {
      return 'Destino selecionado';
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'latlng': '${point.latitude},${point.longitude}',
          'language': 'pt-BR',
          'key': googleApiKey.trim(),
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 8),
          );

      final data = jsonDecode(response.body);

      if (data is! Map) {
        return 'Destino selecionado';
      }

      final status = data['status']?.toString() ?? '';

      if (status != 'OK' || data['results'] is! List) {
        return 'Destino selecionado';
      }

      final results = data['results'] as List;

      if (results.isEmpty || results.first is! Map) {
        return 'Destino selecionado';
      }

      final first = results.first as Map;

      final formatted =
          first['formatted_address']?.toString().trim() ?? '';

      if (formatted.isEmpty) {
        return 'Destino selecionado';
      }

      return formatted;
    } catch (_) {
      return 'Destino selecionado';
    }
  }

  Future<PassengerMapsRoute?> buildRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (!_hasApiKey) {
      return _fallbackRoute(origin, destination);
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/directions/json',
        {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'mode': 'driving',
          'language': 'pt-BR',
          'region': 'br',
          'key': googleApiKey.trim(),
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
          );

      final data = jsonDecode(response.body);

      if (data is! Map) {
        return _fallbackRoute(origin, destination);
      }

      final status = data['status']?.toString() ?? '';

      if (status != 'OK') {
        return _fallbackRoute(origin, destination);
      }

      final routes = data['routes'];

      if (routes is! List || routes.isEmpty || routes.first is! Map) {
        return _fallbackRoute(origin, destination);
      }

      final route = routes.first as Map;
      final legs = route['legs'];

      if (legs is! List || legs.isEmpty || legs.first is! Map) {
        return _fallbackRoute(origin, destination);
      }

      final leg = legs.first as Map;

      final meters = (leg['distance']?['value'] as num?)?.toDouble() ??
          _distanceMeters(origin, destination);

      final seconds = (leg['duration']?['value'] as num?)?.toInt() ??
          ((meters / 1000) / 35 * 3600).round();

      final encoded = route['overview_polyline']?['points']?.toString();

      if (encoded == null || encoded.isEmpty) {
        return PassengerMapsRoute(
          points: [origin, destination],
          distanceKm: meters / 1000,
          distanceText: leg['distance']?['text']?.toString() ??
              '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km',
          eta: leg['duration']?['text']?.toString() ?? _formatEta(seconds),
        );
      }

      final decodedPoints = decodePolyline(encoded);

      if (decodedPoints.length < 2) {
        return PassengerMapsRoute(
          points: [origin, destination],
          distanceKm: meters / 1000,
          distanceText: leg['distance']?['text']?.toString() ??
              '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km',
          eta: leg['duration']?['text']?.toString() ?? _formatEta(seconds),
        );
      }

      return PassengerMapsRoute(
        points: decodedPoints,
        distanceKm: meters / 1000,
        distanceText: leg['distance']?['text']?.toString() ??
            '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km',
        eta: leg['duration']?['text']?.toString() ?? _formatEta(seconds),
      );
    } catch (_) {
      return _fallbackRoute(origin, destination);
    }
  }

  PassengerMapsRoute _fallbackRoute(
    LatLng origin,
    LatLng destination,
  ) {
    final meters = _distanceMeters(origin, destination);
    final km = meters / 1000;
    final seconds = (km / 35 * 3600).round();

    return PassengerMapsRoute(
      points: [origin, destination],
      distanceKm: km,
      distanceText: '${km.toStringAsFixed(1).replaceAll('.', ',')} km',
      eta: _formatEta(seconds),
    );
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;

    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);

    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);

    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);

    return earthRadius * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  double _toRad(double degree) {
    return degree * pi / 180;
  }

  String _formatEta(int seconds) {
    final safeSeconds = seconds <= 0 ? 60 : seconds;
    final minutes = max(1, (safeSeconds / 60).round());

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final rest = minutes % 60;

    if (rest == 0) {
      return '${hours}h';
    }

    return '${hours}h ${rest}min';
  }

  List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];

    int index = 0;
    int lat = 0;
    int lng = 0;

    try {
      while (index < encoded.length) {
        int b;
        int shift = 0;
        int result = 0;

        do {
          if (index >= encoded.length) return points;

          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        final dLat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
        lat += dLat;

        shift = 0;
        result = 0;

        do {
          if (index >= encoded.length) return points;

          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);

        final dLng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
        lng += dLng;

        points.add(
          LatLng(
            lat / 1E5,
            lng / 1E5,
          ),
        );
      }
    } catch (_) {
      return points;
    }

    return points;
  }

  LatLngBounds boundsFromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(-11.6724, -61.1936),
        northeast: const LatLng(-11.6723, -61.1935),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    if (minLat == maxLat) {
      minLat -= 0.001;
      maxLat += 0.001;
    }

    if (minLng == maxLng) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}