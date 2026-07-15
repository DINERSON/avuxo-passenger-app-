import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/ride_step.dart';
import '../models/ride_type.dart';

class PassengerHomeController extends ChangeNotifier {
  RideStep step = RideStep.idle;

  LatLng? currentLocation;
  LatLng? destination;
  LatLng? driverLocation;

  String? currentAddress;
  String? destinationLabel;

  int selectedRide = 0;

  double distanceKm = 0;
  double price = 0;
  double finalPrice = 0;
  double rating = 5;

  String eta = '--';
  String distanceText = '--';

  String driverName = '';
  String driverVehicle = '';
  String driverPlate = '';
  String driverColor = '';
  String driverRating = '5.0';
  String driverEta = 'Chegando em instantes';

  String driverPhoto = '';
  String vehiclePhoto = '';

  bool loadingLocation = false;
  bool loadingRoute = false;
  bool panelExpanded = true;
  bool requestingRide = false;
  bool cancellingRide = false;
  bool chatOpen = false;
  bool sendingChat = false;

  final List<Map<String, dynamic>> chatMessages = [];

  RideType get currentRideType {
    if (selectedRide < 0 || selectedRide >= passengerRideTypes.length) {
      return passengerRideTypes.first;
    }

    return passengerRideTypes[selectedRide];
  }

  bool get hasDestination => destination != null;

  bool get canSelectDestination {
    return step == RideStep.idle || step == RideStep.destinationSelected;
  }

  bool get isSearching => step == RideStep.searching;

  bool get hasDriver {
    return step == RideStep.driverFound ||
        step == RideStep.driverArriving ||
        step == RideStep.tripRunning;
  }

  bool get isTripRunning => step == RideStep.tripRunning;

  bool get isFinished => step == RideStep.finished;

  void setLoadingLocation(bool value) {
    if (loadingLocation == value) return;
    loadingLocation = value;
    notifyListeners();
  }

  void setLoadingRoute(bool value) {
    if (loadingRoute == value) return;
    loadingRoute = value;
    notifyListeners();
  }

  void setCurrentLocation(LatLng value) {
    currentLocation = value;
    notifyListeners();
  }

  void setCurrentAddress(String value) {
    currentAddress = value;
    notifyListeners();
  }

  void selectDestination({
    required LatLng point,
    required String label,
  }) {
    destination = point;
    destinationLabel = label;
    driverLocation = null;
    step = RideStep.destinationSelected;
    panelExpanded = true;
    requestingRide = false;
    cancellingRide = false;
    notifyListeners();
  }

  void setRouteInfo({
    required double distanceKm,
    required String distanceText,
    required String eta,
  }) {
    this.distanceKm = distanceKm < 0 ? 0 : distanceKm;
    this.distanceText = distanceText;
    this.eta = eta;
    calculatePrice();
    notifyListeners();
  }

  void changeRide(int index) {
    if (step != RideStep.destinationSelected) return;

    if (index < 0 || index >= passengerRideTypes.length) {
      return;
    }

    selectedRide = index;
    calculatePrice();
    notifyListeners();
  }

  void calculatePrice() {
    final ride = currentRideType;
    final basePrice = 7.50 + (distanceKm * 2.80);
    price = basePrice * ride.multiplier;
    finalPrice = price;
  }

  void startSearching() {
    requestingRide = true;
    cancellingRide = false;
    step = RideStep.searching;
    panelExpanded = true;

    driverName = '';
    driverVehicle = '';
    driverPlate = '';
    driverColor = '';
    driverRating = '5.0';
    driverEta = 'Chegando em instantes';
    driverPhoto = '';
    vehiclePhoto = '';
    driverLocation = null;

    chatMessages.clear();
    notifyListeners();
  }

  void stopRequesting() {
    if (!requestingRide) return;
    requestingRide = false;
    notifyListeners();
  }

  void driverAccepted() {
    requestingRide = false;
    cancellingRide = false;
    step = RideStep.driverFound;
    panelExpanded = true;
    notifyListeners();
  }

  void driverArriving() {
    requestingRide = false;
    cancellingRide = false;
    step = RideStep.driverArriving;
    panelExpanded = true;
    notifyListeners();
  }

  void tripStarted() {
    requestingRide = false;
    cancellingRide = false;
    step = RideStep.tripRunning;
    panelExpanded = false;
    notifyListeners();
  }

  void tripFinished() {
    requestingRide = false;
    cancellingRide = false;
    step = RideStep.finished;
    panelExpanded = true;
    finalPrice = finalPrice > 0 ? finalPrice : price;
    notifyListeners();
  }

  void setDriverData(Map driver) {
    final name = driver['name'] ??
        driver['driverName'] ??
        driver['fullName'] ??
        driver['full_name'];

    if (name != null && '$name'.trim().isNotEmpty) {
      driverName = '$name'.trim();
    }

    final brand =
        driver['carBrand'] ?? driver['brand'] ?? driver['vehicleBrand'];

    final model =
        driver['carModel'] ?? driver['model'] ?? driver['vehicleModel'];

    final vehicle = driver['vehicle'] ??
        driver['car'] ??
        driver['vehicleName'] ??
        driver['carInfo'];

    String nextVehicle = '';

    if (vehicle != null && '$vehicle'.trim().isNotEmpty) {
      nextVehicle = '$vehicle'.trim();
    } else {
      final parts = [
        if (brand != null && '$brand'.trim().isNotEmpty) '$brand'.trim(),
        if (model != null && '$model'.trim().isNotEmpty) '$model'.trim(),
      ];

      if (parts.isNotEmpty) {
        nextVehicle = parts.join(' ');
      }
    }

    final color =
        driver['carColor'] ?? driver['color'] ?? driver['vehicleColor'];

    if (color != null && '$color'.trim().isNotEmpty) {
      driverColor = '$color'.trim();
    }

    if (nextVehicle.isNotEmpty) {
      if (driverColor.isNotEmpty &&
          !nextVehicle.toLowerCase().contains(driverColor.toLowerCase())) {
        driverVehicle = '$nextVehicle • $driverColor';
      } else {
        driverVehicle = nextVehicle;
      }
    }

    final plate = driver['plate'] ??
        driver['carPlate'] ??
        driver['licensePlate'] ??
        driver['vehiclePlate'];

    if (plate != null && '$plate'.trim().isNotEmpty) {
      driverPlate = '$plate'.trim().toUpperCase();
    }

    final ratingValue =
        driver['rating'] ?? driver['driverRating'] ?? driver['stars'];

    if (ratingValue != null && '$ratingValue'.trim().isNotEmpty) {
      driverRating = '$ratingValue'.trim();
    }

    final etaValue = driver['eta'] ??
        driver['arrivalEta'] ??
        driver['driverEta'] ??
        driver['timeToArrival'];

    if (etaValue != null && '$etaValue'.trim().isNotEmpty) {
      driverEta = '$etaValue'.trim();
    }

    final lat = driver['lat'] ??
        driver['latitude'] ??
        driver['driverLat'] ??
        driver['driverLatitude'];

    final lng = driver['lng'] ??
        driver['longitude'] ??
        driver['driverLng'] ??
        driver['driverLongitude'];

    if (lat != null && lng != null) {
      final parsedLat = double.tryParse('$lat');
      final parsedLng = double.tryParse('$lng');

      if (parsedLat != null && parsedLng != null) {
        driverLocation = LatLng(parsedLat, parsedLng);
      }
    }

    final photo = driver['photo'] ??
        driver['driverPhoto'] ??
        driver['profilePhoto'] ??
        driver['profileImage'] ??
        driver['avatar'] ??
        '';

    final carPhoto = driver['vehiclePhoto'] ??
        driver['carPhoto'] ??
        driver['vehicleImage'] ??
        driver['carImage'] ??
        '';

    if ('$photo'.trim().isNotEmpty) {
      driverPhoto = '$photo'.trim();
    }

    if ('$carPhoto'.trim().isNotEmpty) {
      vehiclePhoto = '$carPhoto'.trim();
    }

    notifyListeners();
  }

  void setChatMessages(List<Map<String, dynamic>> messages) {
    chatMessages
      ..clear()
      ..addAll(messages);

    notifyListeners();
  }

  void addLocalChatMessage(String text) {
    final clean = text.trim();

    if (clean.isEmpty) return;

    chatMessages.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'sender': 'passenger',
      'from': 'passenger',
      'role': 'passenger',
      'message': clean,
      'text': clean,
      'createdAt': DateTime.now().toIso8601String(),
      'local': true,
    });

    notifyListeners();
  }

  void resetRide() {
    step = RideStep.idle;

    destination = null;
    destinationLabel = null;
    driverLocation = null;

    selectedRide = 0;

    distanceKm = 0;
    price = 0;
    finalPrice = 0;
    rating = 5;

    eta = '--';
    distanceText = '--';

    driverName = '';
    driverVehicle = '';
    driverPlate = '';
    driverColor = '';
    driverRating = '5.0';
    driverEta = 'Chegando em instantes';
    driverPhoto = '';
    vehiclePhoto = '';

    panelExpanded = true;
    requestingRide = false;
    cancellingRide = false;
    chatOpen = false;
    sendingChat = false;

    chatMessages.clear();

    notifyListeners();
  }
}