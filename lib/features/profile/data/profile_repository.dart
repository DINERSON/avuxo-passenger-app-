import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../auth/domain/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserProfile> getMe() async {
    try {
      final response =
          await _apiClient.instance.get<Map<String, dynamic>>(
        '/users/me',
      );

      final body = response.data;

      if (body == null) {
        throw Exception('Resposta vazia do servidor');
      }

      final rawData = body['data'];

      if (rawData is! Map<String, dynamic>) {
        throw Exception('Perfil inválido');
      }

      return UserProfile.fromJson(rawData);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Erro ao carregar perfil',
      );
    } catch (e) {
      throw Exception(
        'Falha ao carregar perfil: $e',
      );
    }
  }
}