import '../../../shared/models/common_models.dart';

class PlaceSuggestion {
  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;
}

enum RideStatus {
  requested,
  findingDriver,
  assigned,
  driverArriving,
  inProgress,
  completed,
  cancelled,
}

RideStatus rideStatusFromApi(String value) {
  switch (value.toLowerCase().trim()) {
    case 'finding_driver':
    case 'searching':
      return RideStatus.findingDriver;

    case 'assigned':
    case 'accepted':
      return RideStatus.assigned;

    case 'driver_arriving':
    case 'arrived':
      return RideStatus.driverArriving;

    case 'in_progress':
    case 'started':
      return RideStatus.inProgress;

    case 'completed':
    case 'finished':
      return RideStatus.completed;

    case 'cancelled':
    case 'canceled':
      return RideStatus.cancelled;

    default:
      return RideStatus.requested;
  }
}

class DriverInfo {
  DriverInfo({
    required this.id,
    required this.name,
    this.carModel,
    this.plate,
    this.phone,
    this.rating,
    this.driverPhoto,
    this.vehiclePhoto,
  });

  final String id;
  final String name;
  final String? carModel;
  final String? plate;
  final String? phone;
  final double? rating;
  final String? driverPhoto;
  final String? vehiclePhoto;
}

class Ride {
  Ride({
    required this.id,
    required this.status,
    required this.fare,
    required this.distanceKm,
    required this.pickup,
    required this.destination,
    this.driverId,
    this.driver,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final RideStatus status;
  final double fare;
  final double distanceKm;
  final Coordinate pickup;
  final Coordinate destination;
  final String? driverId;
  final DriverInfo? driver;
  final DateTime? createdAt;
  final DateTime? completedAt;

  factory Ride.fromJson(Map<String, dynamic> json) {
    final driverMap = _safeMap(json['driver']);

    return Ride(
      id: (json['rideId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      status: rideStatusFromApi((json['status'] ?? '').toString()),
      fare: _toDouble(json['fare'] ?? json['price'] ?? json['amount']),
      distanceKm: _toDouble(
        json['distanceKm'] ?? json['distance_km'] ?? json['distance'],
      ),
      pickup: Coordinate.fromJson(
        _safeMap(json['pickup']).isNotEmpty
            ? _safeMap(json['pickup'])
            : <String, dynamic>{
                'lat': json['pickupLat'] ?? json['originLat'],
                'lng': json['pickupLng'] ?? json['originLng'],
                'address': json['pickupAddress'] ?? json['originAddress'],
              },
      ),
      destination: Coordinate.fromJson(
        _safeMap(json['destination']).isNotEmpty
            ? _safeMap(json['destination'])
            : <String, dynamic>{
                'lat': json['destinationLat'] ?? json['destLat'],
                'lng': json['destinationLng'] ?? json['destLng'],
                'address':
                    json['destinationAddress'] ?? json['destAddress'],
              },
      ),
      driverId: (json['driverId'] ?? json['driver_id'])?.toString(),
      driver: driverMap.isNotEmpty
          ? DriverInfo(
              id: (driverMap['id'] ??
                      driverMap['driverId'] ??
                      driverMap['_id'] ??
                      '')
                  .toString(),
              name: (driverMap['name'] ??
                      driverMap['fullName'] ??
                      driverMap['driverName'] ??
                      'Motorista')
                  .toString(),
              carModel: (driverMap['carModel'] ??
                      driverMap['car_model'] ??
                      driverMap['car_info'] ??
                      driverMap['vehicle'])
                  ?.toString(),
              plate: (driverMap['plate'] ??
                      driverMap['carPlate'] ??
                      driverMap['car_plate'])
                  ?.toString(),
              phone: driverMap['phone']?.toString(),
              rating: _toNullableDouble(
                driverMap['rating'] ?? driverMap['rating_avg'],
              ),
              driverPhoto:
                  (driverMap['driverPhoto'] ?? driverMap['photo'])?.toString(),
              vehiclePhoto: driverMap['vehiclePhoto']?.toString(),
            )
          : null,
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
      completedAt: DateTime.tryParse(
        (json['completedAt'] ?? json['completed_at'] ?? '').toString(),
      ),
    );
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }

    return null;
  }
}

class RideHistoryPage {
  RideHistoryPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<Ride> items;
  final int page;
  final int limit;
  final int total;

  factory RideHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems =
        json['items'] ?? json['rides'] ?? json['history'] ?? <dynamic>[];

    return RideHistoryPage(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => Ride.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <Ride>[],
      page: _toInt(json['page'], fallback: 1),
      limit: _toInt(json['limit'], fallback: 20),
      total: _toInt(json['total'], fallback: 0),
    );
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }
}