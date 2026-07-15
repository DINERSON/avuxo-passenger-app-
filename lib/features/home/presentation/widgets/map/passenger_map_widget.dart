import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PassengerMapWidget extends StatelessWidget {
  const PassengerMapWidget({
    super.key,
    required this.initialPosition,
    required this.markers,
    required this.polylines,
    required this.onMapCreated,
    required this.onTap,
  });

  final CameraPosition initialPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final void Function(GoogleMapController controller) onMapCreated;
  final void Function(LatLng point) onTap;

  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#061016"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8EA3A0"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#061016"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#15232B"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#0B151B"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#A8B7B4"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#031018"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]}
]
''';

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: initialPosition,
      style: _darkMapStyle,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      trafficEnabled: false,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      scrollGesturesEnabled: true,
      markers: markers,
      polylines: polylines,
      onMapCreated: onMapCreated,
      onTap: onTap,
    );
  }
}