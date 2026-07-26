import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../features/auth/domain/user_profile.dart';
import '../../features/auth/services/auth_repository.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/ride/data/ride_repository.dart';
import '../../features/ride/domain/ride_models.dart';
import '../../shared/models/common_models.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final appBootstrapProvider = FutureProvider<void>((ref) async {
  final storage = ref.read(localStorageProvider);
  final api = ref.read(apiClientProvider);

  final token = await storage.getToken();
  api.setToken(token);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.read(apiClientProvider),
  );
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  return RideRepository(
    apiClient: ref.read(apiClientProvider),
    placesApiKey: AppConstants.googlePlacesApiKey,
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.read(apiClientProvider),
  );
});

class AuthState {
  const AuthState({
    this.user,
    this.token,
    this.loading = false,
    this.error,
    this.verificationId,
    this.phoneDraft,
  });

  final UserProfile? user;
  final String? token;
  final bool loading;
  final String? error;
  final String? verificationId;
  final String? phoneDraft;

  bool get isLoggedIn {
    return user != null && (token?.isNotEmpty ?? false);
  }

  AuthState copyWith({
    UserProfile? user,
    String? token,
    bool? loading,
    String? error,
    String? verificationId,
    String? phoneDraft,
    bool clearUser = false,
    bool clearToken = false,
    bool clearError = false,
    bool clearVerificationId = false,
    bool clearPhoneDraft = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      token: clearToken ? null : token ?? this.token,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      verificationId:
          clearVerificationId ? null : verificationId ?? this.verificationId,
      phoneDraft: clearPhoneDraft ? null : phoneDraft ?? this.phoneDraft,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState(loading: true)) {
    _loadPersisted();
  }

  final Ref _ref;

  String _handleError(dynamic error) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'Erro desconhecido. Tente novamente.';
    }

    return message;
  }

  Future<void> _loadPersisted() async {
    try {
      final storage = _ref.read(localStorageProvider);
      final user = await storage.getUser();
      final token = await storage.getToken();

      if (!mounted) return;

      if (user != null && token != null && token.isNotEmpty) {
        _ref.read(apiClientProvider).setToken(token);
        state = state.copyWith(
          user: user,
          token: token,
          loading: false,
          clearError: true,
        );
      } else {
        await storage.clearAuth();
        await AuthService.clearLoginSession();

        state = state.copyWith(
          loading: false,
          clearUser: true,
          clearToken: true,
          clearError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        error: _handleError(e),
      );
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    String? email,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = phone.trim();
    final cleanEmail = email?.trim();

    if (cleanName.isEmpty) {
      state = state.copyWith(
        loading: false,
        error: 'Informe seu nome.',
      );
      return;
    }

    if (cleanPhone.isEmpty) {
      state = state.copyWith(
        loading: false,
        error: 'Informe seu telefone.',
      );
      return;
    }

    state = state.copyWith(
      loading: true,
      phoneDraft: cleanPhone,
      clearError: true,
    );

    try {
      await _ref.read(authRepositoryProvider).registerPassenger(
            name: cleanName,
            phone: cleanPhone,
            email: cleanEmail?.isEmpty == true ? null : cleanEmail,
          );

      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        phoneDraft: cleanPhone,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        error: _handleError(e),
      );
    }
  }

  Future<void> sendOtp(String phone) async {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) {
      state = state.copyWith(
        loading: false,
        error: 'Informe seu telefone.',
      );
      return;
    }

    state = state.copyWith(
      loading: true,
      phoneDraft: cleanPhone,
      clearVerificationId: true,
      clearError: true,
    );

    try {
      await _ref.read(authRepositoryProvider).sendOtp(
            phone: cleanPhone,
            onCodeSent: (id, _) {
              if (!mounted) return;

              state = state.copyWith(
                verificationId: id.toString(),
                phoneDraft: cleanPhone,
                loading: false,
                clearError: true,
              );
            },
          );

      if (!mounted) return;

      if (state.loading && state.verificationId == null) {
        state = state.copyWith(
          loading: false,
          phoneDraft: cleanPhone,
          clearError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        error: _handleError(e),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    final verificationId = state.verificationId;
    final phone = state.phoneDraft;
    final cleanOtp = otp.replaceAll(RegExp(r'\s+'), '');

    if (verificationId == null || verificationId.isEmpty) {
      state = state.copyWith(
        loading: false,
        error: 'Envie o código primeiro.',
      );
      return;
    }

    if (phone == null || phone.isEmpty) {
      state = state.copyWith(
        loading: false,
        error: 'Telefone não encontrado. Envie o código novamente.',
      );
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(cleanOtp)) {
      state = state.copyWith(
        loading: false,
        error: 'Código inválido. Digite os 6 números recebidos.',
      );
      return;
    }

    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {
      final result = await _ref.read(authRepositoryProvider).verifyOtp(
            verificationId: verificationId,
            otp: cleanOtp,
            phone: phone,
          );

      _ref.read(apiClientProvider).setToken(result.$1);
      await _ref.read(localStorageProvider).saveAuth(result.$1, result.$2);

      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        user: result.$2,
        token: result.$1,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        error: _handleError(e),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {
      await _ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // Mesmo que o Firebase falhe no logout, limpamos a sessão local.
    }

    await _ref.read(localStorageProvider).clearAuth();
    _ref.read(apiClientProvider).setToken(null);

    if (!mounted) return;

    state = const AuthState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

class HomeRideState {
  const HomeRideState({
    this.currentLocation,
    this.pickup,
    this.destination,
    this.route = const <LatLng>[],
    this.estimatedFare = 0,
    this.loading = false,
    this.error,
    this.activeRide,
    this.pickupSuggestions = const <PlaceSuggestion>[],
    this.destinationSuggestions = const <PlaceSuggestion>[],
  });

  final Position? currentLocation;
  final Coordinate? pickup;
  final Coordinate? destination;
  final List<LatLng> route;
  final double estimatedFare;
  final bool loading;
  final String? error;
  final Ride? activeRide;
  final List<PlaceSuggestion> pickupSuggestions;
  final List<PlaceSuggestion> destinationSuggestions;

  bool get canRequestRide {
    return pickup != null && destination != null && !loading;
  }

  HomeRideState copyWith({
    Position? currentLocation,
    Coordinate? pickup,
    Coordinate? destination,
    List<LatLng>? route,
    double? estimatedFare,
    bool? loading,
    String? error,
    Ride? activeRide,
    List<PlaceSuggestion>? pickupSuggestions,
    List<PlaceSuggestion>? destinationSuggestions,
    bool clearPickup = false,
    bool clearDestination = false,
    bool clearRoute = false,
    bool clearError = false,
    bool clearActiveRide = false,
    bool clearPickupSuggestions = false,
    bool clearDestinationSuggestions = false,
  }) {
    return HomeRideState(
      currentLocation: currentLocation ?? this.currentLocation,
      pickup: clearPickup ? null : pickup ?? this.pickup,
      destination: clearDestination ? null : destination ?? this.destination,
      route: clearRoute ? const <LatLng>[] : route ?? this.route,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      activeRide: clearActiveRide ? null : activeRide ?? this.activeRide,
      pickupSuggestions: clearPickupSuggestions
          ? const <PlaceSuggestion>[]
          : pickupSuggestions ?? this.pickupSuggestions,
      destinationSuggestions: clearDestinationSuggestions
          ? const <PlaceSuggestion>[]
          : destinationSuggestions ?? this.destinationSuggestions,
    );
  }
}

class HomeRideNotifier extends StateNotifier<HomeRideState> {
  HomeRideNotifier(this._ref) : super(const HomeRideState());

  final Ref _ref;

  String _handleError(dynamic error) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'Erro desconhecido. Tente novamente.';
    }

    return message;
  }

  Future<void> initCurrentLocation() async {
    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        state = state.copyWith(
          loading: false,
          error: 'Ative a localização do celular.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        state = state.copyWith(
          loading: false,
          error:
              'Permissão de localização bloqueada. Ative nas configurações do celular.',
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        state = state.copyWith(
          loading: false,
          error: 'Permissão de localização negada.',
        );
        return;
      }

      final current = await Geolocator.getCurrentPosition();

      final pickup = Coordinate(
        lat: current.latitude,
        lng: current.longitude,
        address: 'Localização atual',
      );

      if (!mounted) return;

      state = state.copyWith(
        currentLocation: current,
        pickup: pickup,
        loading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        error: _handleError(e),
      );
    }
  }

  Future<void> searchPickup(String input) async {
    final cleanInput = input.trim();

    if (cleanInput.length < 3) {
      state = state.copyWith(
        clearPickupSuggestions: true,
        clearError: true,
      );
      return;
    }

    try {
      final items = await _ref.read(rideRepositoryProvider).autocomplete(
            cleanInput,
          );

      if (!mounted) return;

      state = state.copyWith(
        pickupSuggestions: items,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        clearPickupSuggestions: true,
        error: _handleError(e),
      );
    }
  }

  Future<void> searchDestination(String input) async {
    final cleanInput = input.trim();

    if (cleanInput.length < 3) {
      state = state.copyWith(
        clearDestinationSuggestions: true,
        clearError: true,
      );
      return;
    }

    try {
      final items = await _ref.read(rideRepositoryProvider).autocomplete(
            cleanInput,
          );

      if (!mounted) return;

      state = state.copyWith(
        destinationSuggestions: items,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        clearDestinationSuggestions: true,
        error: _handleError(e),
      );
    }
  }

  Future<void> selectPickup(PlaceSuggestion suggestion) async {
    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {
      final location = await _ref.read(rideRepositoryProvider).placeDetails(
            suggestion.placeId,
          );

      if (!mounted) return;

      state = state.copyWith(
        pickup: location,
        loading: false,
        clearPickupSuggestions: true,
        clearError: true,
      );

      await _updateRouteAndFare();
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        error: _handleError(e),
      );
    }
  }

  Future<void> selectDestination(PlaceSuggestion suggestion) async {
    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {
      final location = await _ref.read(rideRepositoryProvider).placeDetails(
            suggestion.placeId,
          );

      if (!mounted) return;

      state = state.copyWith(
        destination: location,
        loading: false,
        clearDestinationSuggestions: true,
        clearError: true,
      );

      await _updateRouteAndFare();
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        error: _handleError(e),
      );
    }
  }

  Future<void> _updateRouteAndFare() async {
    final pickup = state.pickup;
    final destination = state.destination;

    if (pickup == null || destination == null) {
      return;
    }

    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {
      final route = await _ref.read(rideRepositoryProvider).routePreview(
            from: pickup,
            to: destination,
          );

      final distanceKm = Geolocator.distanceBetween(
            pickup.lat,
            pickup.lng,
            destination.lat,
            destination.lng,
          ) /
          1000.0;

      final fare = 5.0 + (distanceKm * 2.5);

      if (!mounted) return;

      state = state.copyWith(
        route: route,
        estimatedFare: fare,
        loading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        clearRoute: true,
        error: _handleError(e),
      );
    }
  }

  Future<void> requestRide() async {
    final pickup = state.pickup;
    final destination = state.destination;

    if (pickup == null || destination == null) {
      state = state.copyWith(
        loading: false,
        error: 'Escolha o local de embarque e o destino.',
      );
      return;
    }

    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {
      final ride = await _ref.read(rideRepositoryProvider).requestRide(
            pickup: pickup,
            destination: destination,
          );

      if (!mounted) return;

      state = state.copyWith(
        activeRide: ride,
        loading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        loading: false,
        error: _handleError(e),
      );
    }
  }

  void clearActiveRide() {
    state = state.copyWith(
      clearActiveRide: true,
      clearError: true,
    );
  }

  void resetRideDraft() {
    state = state.copyWith(
      clearDestination: true,
      clearRoute: true,
      estimatedFare: 0,
      clearPickupSuggestions: true,
      clearDestinationSuggestions: true,
      clearActiveRide: true,
      clearError: true,
      loading: false,
    );
  }
}

final homeRideProvider = StateNotifierProvider<HomeRideNotifier, HomeRideState>(
  (ref) => HomeRideNotifier(ref),
);

final rideStatusStreamProvider = StreamProvider.family<Ride, String>(
  (ref, rideId) {
    return ref.read(rideRepositoryProvider).pollRideStatus(rideId);
  },
);

final rideHistoryProvider = FutureProvider<RideHistoryPage>((ref) {
  return ref.read(rideRepositoryProvider).getRideHistory();
});

final profileProvider = FutureProvider<UserProfile>((ref) {
  return ref.read(profileRepositoryProvider).getMe();
});
