import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';
import 'auth_service.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
  }) : _api = apiClient.instance;

  final Dio _api;

  Map<String, dynamic>? _decodeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return null;
  }

  String? _extractToken(Map<String, dynamic> data) {
    final directToken = data['token'] ??
        data['accessToken'] ??
        data['jwt'] ??
        data['authToken'];

    if (directToken != null && directToken.toString().trim().isNotEmpty) {
      return directToken.toString().trim();
    }

    final nestedData = _decodeMap(data['data']);
    if (nestedData != null) {
      final nestedToken = nestedData['token'] ??
          nestedData['accessToken'] ??
          nestedData['jwt'] ??
          nestedData['authToken'];

      if (nestedToken != null && nestedToken.toString().trim().isNotEmpty) {
        return nestedToken.toString().trim();
      }
    }

    return null;
  }

  Map<String, dynamic>? _extractUserMap(Map<String, dynamic> data) {
    final user = _decodeMap(data['user']);
    if (user != null) {
      return user;
    }

    final passenger = _decodeMap(data['passenger']);
    if (passenger != null) {
      return passenger;
    }

    final profile = _decodeMap(data['profile']);
    if (profile != null) {
      return profile;
    }

    final nestedData = _decodeMap(data['data']);
    if (nestedData != null) {
      return _decodeMap(nestedData['user']) ??
          _decodeMap(nestedData['passenger']) ??
          _decodeMap(nestedData['profile']);
    }

    return null;
  }

  UserProfile _buildFallbackUser({
    required String uid,
    required String phone,
    String? name,
    String? email,
  }) {
    return UserProfile(
      id: uid,
      name: name?.trim().isNotEmpty == true ? name!.trim() : 'Passageiro',
      phone: phone,
      email: email?.trim().isNotEmpty == true ? email!.trim() : null,
      role: 'passenger',
    );
  }

  UserProfile _buildUserFromBackendOrFallback({
    required Map<String, dynamic> backendData,
    required String uid,
    required String phone,
    String? name,
    String? email,
  }) {
    final userMap = _extractUserMap(backendData);

    if (userMap == null) {
      return _buildFallbackUser(
        uid: uid,
        phone: phone,
        name: name,
        email: email,
      );
    }

    final fixedUserMap = Map<String, dynamic>.from(userMap);

    fixedUserMap['id'] = fixedUserMap['id'] ??
        fixedUserMap['_id'] ??
        fixedUserMap['uid'] ??
        fixedUserMap['firebaseUid'] ??
        uid;

    fixedUserMap['name'] = fixedUserMap['name'] ?? name ?? 'Passageiro';
    fixedUserMap['phone'] = fixedUserMap['phone'] ?? phone;
    fixedUserMap['email'] = fixedUserMap['email'] ?? email;
    fixedUserMap['role'] = fixedUserMap['role'] ?? 'passenger';

    return UserProfile.fromJson(fixedUserMap);
  }

  Future<void> registerPassenger({
    required String name,
    required String phone,
    String? email,
  }) async {
    final cleanName = name.trim();
    final cleanPhone = AuthService.normalizeBrazilPhone(phone);
    final cleanEmail = email?.trim();

    if (cleanName.isEmpty) {
      throw Exception('Informe seu nome.');
    }

    if (cleanPhone.isEmpty) {
      throw Exception('Informe seu telefone.');
    }

    await safePost(
      _api,
      '/auth/register',
      data: {
        'name': cleanName,
        'phone': cleanPhone,
        'email': cleanEmail?.isNotEmpty == true ? cleanEmail : null,
        'role': 'passenger',
      },
    );
  }

  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
  }) async {
    final normalizedPhone = AuthService.normalizeBrazilPhone(phone);

    if (normalizedPhone.trim().isEmpty) {
      throw Exception('Informe seu telefone.');
    }

    await AuthService.sendPhoneOtp(
      phone: normalizedPhone,
      onCodeSent: (verificationId) {
        if (verificationId.trim().isEmpty) {
          throw Exception('Código de verificação inválido.');
        }

        onCodeSent(verificationId, null);
      },
      onError: (error) {
        throw Exception(error);
      },
    );
  }

  Future<(String token, UserProfile user)> verifyOtp({
    required String verificationId,
    required String otp,
    required String phone,
  }) async {
    final cleanVerificationId = verificationId.trim();
    final cleanOtp = otp.trim();
    final normalizedPhone = AuthService.normalizeBrazilPhone(phone);

    if (cleanVerificationId.isEmpty) {
      throw Exception('Envie o código novamente.');
    }

    if (cleanOtp.isEmpty) {
      throw Exception('Informe o código recebido.');
    }

    if (normalizedPhone.trim().isEmpty) {
      throw Exception('Telefone inválido.');
    }

    await AuthService.verifyOtp(
      verificationId: cleanVerificationId,
      smsCode: cleanOtp,
      phone: normalizedPhone,
    );

    final firebaseUser = AuthService.currentUser;

    if (firebaseUser == null) {
      throw Exception('Usuário não autenticado.');
    }

    final firebaseToken = await firebaseUser.getIdToken();

    if (firebaseToken == null || firebaseToken.trim().isEmpty) {
      throw Exception('Token Firebase não recebido.');
    }

    final response = await safePost(
      _api,
      '/auth/verify-otp',
      data: {
        'phone': normalizedPhone,
        'otp': cleanOtp,
        'role': 'passenger',
        'firebaseUid': firebaseUser.uid,
        'firebaseToken': firebaseToken,
      },
    );

    final backendData = _decodeMap(response.data) ?? <String, dynamic>{};

    final backendToken = _extractToken(backendData);

    final tokenToUse = backendToken?.trim().isNotEmpty == true
        ? backendToken!.trim()
        : firebaseToken.trim();

    final user = _buildUserFromBackendOrFallback(
      backendData: backendData,
      uid: firebaseUser.uid,
      phone: firebaseUser.phoneNumber?.trim().isNotEmpty == true
          ? firebaseUser.phoneNumber!.trim()
          : normalizedPhone,
      name: firebaseUser.displayName,
      email: firebaseUser.email,
    );

    return (tokenToUse, user);
  }

  Future<void> signOut() async {
    await AuthService.logout();
  }
}