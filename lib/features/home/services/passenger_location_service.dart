import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PassengerLocationService {
  static const LatLng fallbackLocation = LatLng(
    -11.433865,
    -61.456665,
  );

  Future<LatLng?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 12),
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      return LatLng(
        position.latitude,
        position.longitude,
      );
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();

        if (last != null) {
          return LatLng(
            last.latitude,
            last.longitude,
          );
        }
      } catch (_) {}

      return fallbackLocation;
    }
  }

  double distanceBetweenMeters(
    LatLng a,
    LatLng b,
  ) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }
}