import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_profile.dart';
import 'auth_service.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
  }) : _api = apiClient.instance;

  final Dio _api;

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
    final cleanOtp = otp.replaceAll(RegExp(r'\s+'), '');
    final normalizedPhone = AuthService.normalizeBrazilPhone(phone);

    if (cleanVerificationId.isEmpty) {
      throw Exception('Envie o código novamente.');
    }

    if (!RegExp(r'^\d{6}$').hasMatch(cleanOtp)) {
      throw Exception('Código inválido. Digite os 6 números recebidos.');
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

    // O SMS foi emitido pelo Firebase; portanto, o código só pode ser
    // validado pelo Firebase. A sessão usa o ID token confirmado acima e não
    // envia o mesmo OTP para o fluxo legado do backend.
    final user = _buildFallbackUser(
      uid: firebaseUser.uid,
      phone: firebaseUser.phoneNumber?.trim().isNotEmpty == true
          ? firebaseUser.phoneNumber!.trim()
          : normalizedPhone,
      name: firebaseUser.displayName,
      email: firebaseUser.email,
    );

    return (firebaseToken.trim(), user);
  }

  Future<void> signOut() async {
    await AuthService.logout();
  }
}
