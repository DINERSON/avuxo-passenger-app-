import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/providers/app_providers.dart';
import '../controllers/passenger_home_controller.dart';
import '../models/ride_step.dart';
import '../models/ride_type.dart';
import '../services/passenger_chat_service.dart';
import '../services/passenger_location_service.dart';
import '../services/passenger_maps_service.dart';
import '../services/passenger_ride_service.dart';
import '../services/passenger_socket_service.dart';
import 'widgets/chat/ride_chat_sheet.dart';
import 'widgets/dialogs/arrival_dialog.dart';
import 'widgets/map/passenger_map_widget.dart';
import 'widgets/passenger_side_menu.dart';
import 'widgets/rides/driver_found_panel.dart';
import 'widgets/rides/ride_options_panel.dart';
import 'widgets/rides/searching_driver_panel.dart';
import 'widgets/rides/trip_finished_panel.dart';
import 'widgets/rides/trip_running_panel.dart';
import 'widgets/search/destination_search_screen.dart';
import 'widgets/status/top_status_bar.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  static const String googleApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyCUmVhGZ_NQtVX7ZebWECXa3cDAk74-NUI',
  );

  static const String backendBaseUrl =
      'https://avuxo-backend-production.up.railway.app';

  static const LatLng initialCity = LatLng(-11.6724, -61.1936);

  final PassengerHomeController controller = PassengerHomeController();

  late final PassengerLocationService locationService;
  late final PassengerMapsService mapsService;
  late final PassengerRideService rideService;
  late final PassengerChatService chatService;
  late final PassengerSocketService socketService;

  GoogleMapController? mapController;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  final List<LatLng> routePoints = [];
  final List<LatLng> driverRoutePoints = [];

  Timer? rideStatusTimer;
  Timer? chatTimer;
  Timer? driverRouteDebounce;

  OverlayEntry? notificationOverlay;

  bool arrivalDialogShown = false;
  bool socketJoinedRide = false;

  String lastRideStatus = '';
  String? currentRideId;

  DateTime? lastNotificationTime;

  String get passengerName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(' ').first;
    }

    final email = user?.email?.trim();

    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Passageiro';
  }

  String get passengerFullName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user?.email?.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Passageiro AVUXO';
  }

  String get passengerPhoto {
    return FirebaseAuth.instance.currentUser?.photoURL ?? '';
  }

  String get passengerId {
    final user = FirebaseAuth.instance.currentUser;

    final uid = user?.uid.trim();
    if (uid != null && uid.isNotEmpty) {
      return uid;
    }

    final phone = user?.phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) {
      return phone;
    }

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'passenger-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void initState() {
    super.initState();

    locationService = PassengerLocationService();
    mapsService = PassengerMapsService(googleApiKey: googleApiKey);
    rideService = PassengerRideService(baseUrl: backendBaseUrl);
    chatService = PassengerChatService(baseUrl: backendBaseUrl);
    socketService = PassengerSocketService(baseUrl: backendBaseUrl);

    controller.addListener(_refresh);

    _loadCurrentLocation();
    _connectSocket();
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();

    rideStatusTimer?.cancel();
    chatTimer?.cancel();
    driverRouteDebounce?.cancel();

    notificationOverlay?.remove();
    notificationOverlay = null;

    socketService.dispose();

    mapController?.dispose();
    mapController = null;

    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _safeRefresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _connectSocket() {
    socketService.connect(
      passengerId: passengerId,
      onRideData: _handleRideData,
      onDriverLocation: _handleDriverLocation,
      onChatUpdated: _handleChatData,
    );
  }

  void _joinCurrentRideRoom(String rideId) {
    final cleanRideId = rideId.trim();

    if (cleanRideId.isEmpty) return;

    if (currentRideId == cleanRideId && socketJoinedRide) return;

    currentRideId = cleanRideId;
    socketJoinedRide = true;

    socketService.joinRide(cleanRideId);
    socketService.requestCurrentRide(rideId: cleanRideId);
    socketService.requestChat(rideId: cleanRideId);
  }

  Future<void> _loadCurrentLocation() async {
    if (controller.loadingLocation) return;

    controller.setLoadingLocation(true);

    final location = await locationService.getCurrentLocation();

    if (!mounted) return;

    if (location == null) {
      controller.setLoadingLocation(false);
      _showCenterNotification('Não foi possível pegar sua localização.');
      return;
    }

    controller.setCurrentLocation(location);

    final address = await mapsService.getAddressFromLatLng(location);

    if (!mounted) return;

    controller.setCurrentAddress(address);

    _refreshMarkers();

    await mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 16,
          tilt: 35,
        ),
      ),
    );

    controller.setLoadingLocation(false);
  }

  Future<void> _handleMapTap(LatLng point) async {
    if (!controller.canSelectDestination) {
      _showCenterNotification('Destino bloqueado durante a corrida.');
      return;
    }

    await _selectDestination(point);
  }

  Future<void> _selectDestination(LatLng point) async {
    final label = await mapsService.getAddressFromLatLng(point);

    if (!mounted) return;

    controller.selectDestination(
      point: point,
      label: label,
    );

    _removeDriverRoute();
    _refreshMarkers();

    await _buildRoute();
  }

  Future<void> _openDestinationSearch() async {
    if (!controller.canSelectDestination) {
      _showCenterNotification('Destino bloqueado durante a corrida.');
      return;
    }

    final result = await Navigator.push<DestinationSearchResult>(
      context,
      MaterialPageRoute(
        builder: (_) => DestinationSearchScreen(
          mapsService: mapsService,
        ),
      ),
    );

    if (!mounted || result == null) return;

    controller.selectDestination(
      point: result.point,
      label: result.label,
    );

    _removeDriverRoute();
    _refreshMarkers();

    await _buildRoute();
  }

  Future<void> _buildRoute() async {
    if (controller.currentLocation == null || controller.destination == null) {
      return;
    }

    controller.setLoadingRoute(true);

    final route = await mapsService.buildRoute(
      origin: controller.currentLocation!,
      destination: controller.destination!,
    );

    if (!mounted) return;

    if (route == null) {
      controller.setLoadingRoute(false);
      _showCenterNotification('Erro ao montar rota.');
      return;
    }

    routePoints
      ..clear()
      ..addAll(route.points);

    controller.setRouteInfo(
      distanceKm: route.distanceKm,
      distanceText: route.distanceText,
      eta: route.eta,
    );

    polylines.removeWhere((p) => p.polylineId.value == 'route');

    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: const Color(0xFF24F877),
        width: 8,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    );

    await _fitCamera();

    controller.setLoadingRoute(false);
  }

  Future<void> _buildDriverRoute() async {
    if (controller.driverLocation == null) return;

    final target = controller.step == RideStep.tripRunning
        ? controller.destination
        : controller.currentLocation;

    if (target == null) return;

    final route = await mapsService.buildRoute(
      origin: controller.driverLocation!,
      destination: target,
    );

    if (!mounted) return;

    driverRoutePoints.clear();

    if (route != null) {
      driverRoutePoints.addAll(route.points);
    } else {
      driverRoutePoints.addAll([
        controller.driverLocation!,
        target,
      ]);
    }

    polylines.removeWhere(
      (p) => p.polylineId.value == 'driver_route',
    );

    polylines.add(
      Polyline(
        polylineId: const PolylineId('driver_route'),
        points: driverRoutePoints,
        color: const Color(0xFF24F877),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        patterns: route == null
            ? [
                PatternItem.dash(18),
                PatternItem.gap(10),
              ]
            : [],
      ),
    );

    _safeRefresh();
  }

  void _scheduleDriverRouteUpdate() {
    driverRouteDebounce?.cancel();

    driverRouteDebounce = Timer(
      const Duration(milliseconds: 250),
      () {
        if (!mounted) return;
        _buildDriverRoute();
      },
    );
  }

  void _removeDriverRoute() {
    driverRoutePoints.clear();

    polylines.removeWhere(
      (p) => p.polylineId.value == 'driver_route',
    );

    _safeRefresh();
  }

  void _refreshMarkers() {
    final newMarkers = <Marker>{};

    if (controller.currentLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: controller.currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(
            title: 'Você',
          ),
        ),
      );
    }

    if (controller.destination != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: controller.destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(
            title: 'Destino',
          ),
        ),
      );
    }

    if (controller.driverLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: controller.driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: controller.driverName.isEmpty
                ? 'Motorista AVUXO'
                : controller.driverName,
            snippet: controller.driverVehicle.isEmpty
                ? 'Veículo AVUXO'
                : controller.driverVehicle,
          ),
        ),
      );
    }

    markers
      ..clear()
      ..addAll(newMarkers);

    _safeRefresh();
  }

  Future<void> _fitCamera() async {
    final points = <LatLng>[
      ...routePoints,
      ...driverRoutePoints,
      if (controller.currentLocation != null) controller.currentLocation!,
      if (controller.destination != null) controller.destination!,
      if (controller.driverLocation != null) controller.driverLocation!,
    ];

    if (points.length < 2 || mapController == null) return;

    final bounds = mapsService.boundsFromPoints(points);

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted || mapController == null) return;

    try {
      await mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          110,
        ),
      );
    } catch (_) {}
  }

  String _validOriginName() {
    final current = controller.currentAddress?.trim() ?? '';

    if (current.isNotEmpty &&
        current.toLowerCase() != 'destino selecionado' &&
        current.toLowerCase() != 'origem' &&
        current.toLowerCase() != 'local do passageiro') {
      return current;
    }

    return 'Local atual do passageiro';
  }

  Future<void> _requestRide() async {
    if (controller.requestingRide) return;

    if (controller.currentLocation == null ||
        controller.destination == null ||
        routePoints.isEmpty) {
      _showCenterNotification(
        'Escolha um destino primeiro.',
      );
      return;
    }

    controller.startSearching();

    try {
      final user = FirebaseAuth.instance.currentUser;

      final originName = _validOriginName();
      final destinationName =
          controller.destinationLabel ?? 'Destino AVUXO';

      final data = await rideService.requestRide(
        body: {
          'originLat': controller.currentLocation!.latitude,
          'originLng': controller.currentLocation!.longitude,
          'originName': originName,
          'pickupAddress': originName,
          'pickupLat': controller.currentLocation!.latitude,
          'pickupLng': controller.currentLocation!.longitude,
          'destLat': controller.destination!.latitude,
          'destLng': controller.destination!.longitude,
          'destinationLat': controller.destination!.latitude,
          'destinationLng': controller.destination!.longitude,
          'destinationName': destinationName,
          'destinationLabel': destinationName,
          'destinationAddress': destinationName,
          'price': controller.price,
          'fare': controller.price,
          'total': controller.price,
          'distanceKm': controller.distanceKm,
          'distanceText': controller.distanceText,
          'eta': controller.eta,
          'rideType': controller.currentRideType.name,
          'paymentMethod': 'PIX',
          'platform': 'passenger_app',
          'requestedAt': DateTime.now().toIso8601String(),
          'passengerId': passengerId,
          'passenger': {
            'uid': user?.uid ?? '',
            'id': passengerId,
            'name': passengerName,
            'fullName': passengerFullName,
            'photo': passengerPhoto,
            'email': user?.email ?? '',
            'phone': user?.phoneNumber ?? '',
            'rating': 5,
          },
        },
      );

      if (!mounted) return;

      if (data['success'] == true) {
        final ride = data['ride'];

        if (ride is Map) {
          final rideId = '${ride['rideId'] ?? ride['id'] ?? ''}'.trim();

          if (rideId.isNotEmpty) {
            _joinCurrentRideRoom(rideId);
          }
        }

        _showCenterNotification(
          'Corrida enviada! Procurando motorista...',
        );

        _listenRideStatus();
        _startChatPolling();
      } else {
        controller.step = RideStep.destinationSelected;
        _safeRefresh();

        _showCenterNotification(
          data['message']?.toString() ?? 'Erro ao solicitar corrida.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      controller.step = RideStep.destinationSelected;
      _safeRefresh();

      _showCenterNotification(
        'Erro de conexão com o backend.',
      );
    } finally {
      controller.stopRequesting();
    }
  }

  void _listenRideStatus() {
    rideStatusTimer?.cancel();

    rideStatusTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) async {
        if (currentRideId == null || currentRideId!.isEmpty) {
          return;
        }

        final data = await rideService.getCurrentRide(
          rideId: currentRideId,
        );

        if (!mounted || data == null) return;

        final ride = data['ride'] ?? data;

        _handleRideData(ride);
      },
    );
  }

  void _handleRideData(dynamic data) {
    if (!mounted || data == null) return;

    final ride = data is Map ? (data['ride'] ?? data) : data;

    if (ride is! Map) return;

    final rideId = '${ride['rideId'] ?? ride['id'] ?? ''}'.trim();

    if (rideId.isNotEmpty) {
      _joinCurrentRideRoom(rideId);
    }

    final status = '${ride['status'] ?? ''}'.trim();

    final bool statusChanged =
        status.isNotEmpty && status != lastRideStatus;

    if (statusChanged) {
      lastRideStatus = status;
    }

    final driver = ride['driver'];

    if (ride['price'] != null) {
      controller.finalPrice =
          double.tryParse('${ride['price']}') ?? controller.price;
    }

    if (driver is Map) {
      controller.setDriverData(driver);
      _refreshMarkers();
      _scheduleDriverRouteUpdate();
    }

    if (status == 'pending' || status == 'searching') {
      controller.step = RideStep.searching;
      controller.panelExpanded = true;
      _safeRefresh();
    }

    if (status == 'accepted') {
      controller.driverAccepted();

      if (statusChanged) {
        _showCenterNotification(
          'Motorista aceitou sua corrida!',
        );
      }

      _startChatPolling();
      _scheduleDriverRouteUpdate();
      _fitCamera();
    }

    if (status == 'arriving' || status == 'arrived') {
      controller.driverArriving();

      if (statusChanged) {
        if (!arrivalDialogShown) {
          _showArrivalDialog();
        }

        _showCenterNotification(
          'Motorista chegou ao local.',
        );
      }

      _startChatPolling();
      _scheduleDriverRouteUpdate();
      _fitCamera();
    }

    if (status == 'started' || status == 'in_progress') {
      controller.tripStarted();

      if (statusChanged) {
        _showCenterNotification(
          'Corrida iniciada!',
        );
      }

      _startChatPolling();
      _scheduleDriverRouteUpdate();
      _fitCamera();
    }

    if (status == 'finished' || status == 'completed') {
      rideStatusTimer?.cancel();
      _stopChatPolling();

      if (currentRideId != null) {
        socketService.leaveRide(
          currentRideId!,
        );
      }

      controller.tripFinished();

      if (statusChanged) {
        _showCenterNotification(
          'Corrida finalizada.',
        );
      }
    }

    if (status == 'cancelled' || status == 'canceled') {
      rideStatusTimer?.cancel();
      _stopChatPolling();
      _resetRide('Corrida cancelada.');
    }
  }

  void _handleDriverLocation(dynamic data) {
    if (!mounted || data == null) return;

    final driver = data is Map ? (data['driver'] ?? data) : data;

    if (driver is Map) {
      controller.setDriverData(driver);
      _refreshMarkers();
      _scheduleDriverRouteUpdate();
    }
  }

  void _handleChatData(dynamic data) {
    if (!mounted || data == null) return;

    dynamic chat;

    if (data is Map) {
      chat = data['chat'];
      chat ??= data['messages'];
    } else {
      chat = data;
    }

    if (chat is! List) return;

    final messages = chat.map<Map<String, dynamic>>((item) {
      return Map<String, dynamic>.from(item);
    }).toList();

    controller.setChatMessages(messages);
  }

  void _startChatPolling() {
    if (currentRideId == null || currentRideId!.isEmpty) return;

    chatTimer?.cancel();

    _loadChat();

    chatTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        _loadChat();
      },
    );
  }

  void _stopChatPolling() {
    chatTimer?.cancel();
    chatTimer = null;
  }

  Future<void> _loadChat() async {
    if (currentRideId == null || currentRideId!.isEmpty) return;

    try {
      final messages = await chatService.loadChat(
        rideId: currentRideId,
      );

      if (!mounted) return;

      controller.setChatMessages(messages);
    } catch (_) {}
  }

  Future<void> _sendChatMessage(String text) async {
    if (currentRideId == null || currentRideId!.isEmpty) {
      _showCenterNotification(
        'Corrida ainda não conectada ao chat.',
      );
      return;
    }

    controller.addLocalChatMessage(text);

    if (socketService.connected) {
      socketService.sendChatMessage(
        text,
        rideId: currentRideId,
      );
      return;
    }

    try {
      await chatService.sendMessage(
        text,
        rideId: currentRideId,
      );

      await _loadChat();
    } catch (_) {
      _showCenterNotification(
        'Erro ao enviar mensagem.',
      );
    }
  }

  void _openChat() {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return RideChatSheet(
          messages: controller.chatMessages,
          onSend: _sendChatMessage,
        );
      },
    );
  }

  Future<void> _cancelRide() async {
    if (controller.cancellingRide) return;

    controller.cancellingRide = true;

    try {
      if (currentRideId != null && currentRideId!.isNotEmpty) {
        await rideService.cancelRide(
          rideId: currentRideId!,
        );
      }
    } catch (_) {}

    _resetRide('Corrida cancelada.');
  }

  void _resetRide(String message) {
    rideStatusTimer?.cancel();
    driverRouteDebounce?.cancel();

    _stopChatPolling();

    routePoints.clear();
    driverRoutePoints.clear();
    polylines.clear();

    arrivalDialogShown = false;
    lastRideStatus = '';
    lastNotificationTime = null;

    if (currentRideId != null && currentRideId!.isNotEmpty) {
      socketService.leaveRide(
        currentRideId!,
      );
    }

    currentRideId = null;
    socketJoinedRide = false;

    socketService.clearRide();

    controller.resetRide();

    _refreshMarkers();

    _showCenterNotification(message);
  }

  void _submitReview(
    double rating,
    String comment,
  ) {
    controller.rating = rating;

    _resetRide(
      'Obrigado pela avaliação!',
    );
  }

  void _showArrivalDialog() {
    if (arrivalDialogShown || !mounted) return;

    arrivalDialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return ArrivalDialog(
          driverName: controller.driverName,
        );
      },
    ).then((_) {
      arrivalDialogShown = false;
    });
  }

  void _showCenterNotification(String text) {
    if (!mounted) return;

    final now = DateTime.now();

    if (lastNotificationTime != null &&
        now.difference(lastNotificationTime!).inMilliseconds < 2500) {
      return;
    }

    lastNotificationTime = now;

    notificationOverlay?.remove();
    notificationOverlay = null;

    final overlay = Overlay.maybeOf(context);

    if (overlay == null) {
      return;
    }

    notificationOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          top: MediaQuery.of(overlayContext).padding.top + 155,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1117),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF24F877).withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF24F877).withValues(alpha: 0.10),
                    blurRadius: 25,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF24F877),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(notificationOverlay!);

    Future.delayed(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        notificationOverlay?.remove();
        notificationOverlay = null;
      },
    );
  }

  Widget _buildPanelByStep() {
    if (controller.step == RideStep.idle ||
        controller.step == RideStep.destinationSelected) {
      return RideOptionsPanel(
        rideTypes: passengerRideTypes,
        selectedRide: controller.selectedRide,
        distanceText: controller.distanceText,
        eta: controller.eta,
        price: controller.price,
        loadingRoute: controller.loadingRoute,
        requestingRide: controller.requestingRide,
        onChangeRide: controller.changeRide,
        onRequestRide: _requestRide,
        onOpenSearch: _openDestinationSearch,
      );
    }

    if (controller.step == RideStep.searching) {
      return SearchingDriverPanel(
        onCancel: _cancelRide,
      );
    }

    if (controller.step == RideStep.driverFound ||
        controller.step == RideStep.driverArriving) {
      return DriverFoundPanel(
        driverName: controller.driverName,
        driverVehicle: controller.driverVehicle,
        driverPlate: controller.driverPlate,
        driverPhoto: controller.driverPhoto,
        vehiclePhoto: controller.vehiclePhoto,
        driverRating: controller.driverRating,
        driverEta: controller.driverEta,
        onChat: _openChat,
        onCancel: _cancelRide,
      );
    }

    if (controller.step == RideStep.tripRunning) {
      return TripRunningPanel(
        driverName: controller.driverName,
        destination: controller.destinationLabel ?? 'Destino AVUXO',
        price: controller.finalPrice,
        onChat: _openChat,
      );
    }

    if (controller.step == RideStep.finished) {
      return TripFinishedPanel(
        price: controller.finalPrice,
        onSubmitReview: _submitReview,
      );
    }

    return const SizedBox.shrink();
  }

  void _openSafeRoute(String routeName) {
    Navigator.pop(context);

    try {
      Navigator.pushNamed(context, routeName);
    } catch (_) {
      _showCenterNotification('Tela indisponível no momento.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const initialPosition = CameraPosition(
      target: initialCity,
      zoom: 15.5,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF02040A),
      drawer: PassengerSideMenu(
        onActivity: () {
          _openSafeRoute('/passenger-activity');
        },
        onWallet: () {
          _openSafeRoute('/passenger-wallet');
        },
        onPromotions: () {
          _showCenterNotification(
            'Promoções serão ativadas em breve.',
          );
          Navigator.pop(context);
        },
        onHelp: () {
          _openSafeRoute('/passenger-help');
        },
        onSettings: () {
          _openSafeRoute('/passenger-settings');
        },
        onAccount: () {
          _openSafeRoute('/passenger-account');
        },
        onLogout: () async {
          Navigator.pop(context);

          await ref.read(authNotifierProvider.notifier).signOut();

          if (!context.mounted) return;

          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        },
      ),
      body: Stack(
        children: [
          PassengerMapWidget(
            initialPosition: initialPosition,
            markers: markers,
            polylines: polylines,
            onMapCreated: (controllerMap) {
              mapController = controllerMap;

              if (controller.currentLocation != null) {
                mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: controller.currentLocation!,
                      zoom: 16,
                      tilt: 35,
                    ),
                  ),
                );
              }
            },
            onTap: _handleMapTap,
          ),
          Builder(
            builder: (scaffoldContext) {
              return TopStatusBar(
                title: passengerName,
                subtitle:
                    controller.currentAddress ?? 'Carregando localização...',
                loading: controller.loadingLocation,
                onLocate: _loadCurrentLocation,
                onMenu: () {
                  Scaffold.of(scaffoldContext).openDrawer();
                },
                onNotifications: () {
                  _showCenterNotification(
                    'Nenhuma notificação no momento.',
                  );
                },
              );
            },
          ),
          _buildPanelByStep(),
        ],
      ),
    );
  }
}
