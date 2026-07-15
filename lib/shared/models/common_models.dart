class ApiResponse<T> {
  ApiResponse({
    required this.success,
    required this.data,
    this.message,
  });

  final bool success;
  final T data;
  final String? message;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decoder,
  ) {
    final rawData = json['data'];

    Map<String, dynamic> dataMap;

    if (rawData is Map<String, dynamic>) {
      dataMap = rawData;
    } else if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    } else {
      dataMap = <String, dynamic>{};
    }

    return ApiResponse(
      success: json['success'] == true,
      data: decoder(dataMap),
      message: json['message']?.toString(),
    );
  }
}

class Coordinate {
  Coordinate({
    required this.lat,
    required this.lng,
    this.address,
  });

  final double lat;
  final double lng;
  final String? address;

  factory Coordinate.fromJson(
    Map<String, dynamic> json,
  ) {
    return Coordinate(
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (address != null) 'address': address,
      };

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
            value.replaceAll(',', '.'),
          ) ??
          0;
    }

    return 0;
  }
}