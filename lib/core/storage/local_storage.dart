import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/user_profile.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_profile';

  Future<void> saveAuth(
    String token,
    UserProfile user,
  ) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      throw Exception('Token inválido para salvar sessão.');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      cleanToken,
    );

    await prefs.setString(
      _userKey,
      jsonEncode({
        'id': user.id,
        'name': user.name,
        'phone': user.phone,
        'role': user.role,
        'email': user.email,
      }),
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey)?.trim();

    if (token == null || token.isEmpty) {
      return null;
    }

    return token;
  }

  Future<UserProfile?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_userKey);

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return UserProfile.fromJson(decoded);
      }

      if (decoded is Map) {
        return UserProfile.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }

      await clearAuth();
      return null;
    } catch (_) {
      await clearAuth();
      return null;
    }
  }

  Future<bool> hasAuth() async {
    final token = await getToken();
    final user = await getUser();

    return token != null && user != null;
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_userKey),
    ]);
  }
}