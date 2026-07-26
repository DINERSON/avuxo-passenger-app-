import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient({String? token})
      : _dio = Dio(
          BaseOptions(
            baseUrl: const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'https://avuxo-backend-production.up.railway.app',
            ),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            validateStatus: (status) {
              return status != null && status >= 200 && status < 500;
            },
          ),
        ) {
    _setupInterceptors();
  }

  final Dio _dio;

  Dio get instance => _dio;

  void setToken(String? token) {
    final cleanToken = token?.trim();

    if (cleanToken == null || cleanToken.isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }

    _dio.options.headers['Authorization'] = 'Bearer $cleanToken';
  }

  void _setupInterceptors() {
    _dio.interceptors.clear();

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final firebaseToken =
              await FirebaseAuth.instance.currentUser?.getIdToken();
          if (firebaseToken != null && firebaseToken.trim().isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer ${firebaseToken.trim()}';
          }

          if (kDebugMode) {
            debugPrint('');
            debugPrint('🚀 PASSENGER REQUEST');
            debugPrint('${options.method} ${options.uri}');
            debugPrint('HAS_AUTH: ${options.headers['Authorization'] != null}');

            if (options.data != null) {
              debugPrint('DATA_TYPE: ${options.data.runtimeType}');
            }
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('');
            debugPrint('✅ PASSENGER RESPONSE');
            debugPrint(
              '${response.requestOptions.method} ${response.requestOptions.uri}',
            );
            debugPrint('STATUS: ${response.statusCode}');

            if (response.data != null) {
              debugPrint('DATA_TYPE: ${response.data.runtimeType}');
            }
          }

          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('');
            debugPrint('❌ PASSENGER DIO ERROR');
            debugPrint(
              '${error.requestOptions.method} ${error.requestOptions.uri}',
            );
            debugPrint('MESSAGE: ${error.message}');
            debugPrint('STATUS: ${error.response?.statusCode}');
            debugPrint('RESPONSE: ${error.response?.data}');
          }

          handler.next(error);
        },
      ),
    );
  }
}

bool _isSuccessStatus(int? statusCode) {
  return statusCode != null && statusCode >= 200 && statusCode < 300;
}

String _extractErrorMessage(dynamic data) {
  if (data == null) {
    return 'Erro de conexão. Tente novamente.';
  }

  if (data is String && data.trim().isNotEmpty) {
    return data.trim();
  }

  if (data is Map) {
    final message = data['message'] ??
        data['error'] ??
        data['details'] ??
        data['detail'] ??
        data['msg'];

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString().trim();
    }
  }

  return data.toString();
}

Exception _buildDioExceptionMessage(DioException error) {
  final statusCode = error.response?.statusCode;
  final responseData = error.response?.data;

  if (statusCode == 401) {
    return Exception('Sessão expirada. Faça login novamente.');
  }

  if (statusCode == 403) {
    return Exception('Acesso negado.');
  }

  if (statusCode == 404) {
    return Exception('Informação não encontrada.');
  }

  if (statusCode != null && statusCode >= 500) {
    return Exception('Servidor indisponível. Tente novamente em instantes.');
  }

  final message = _extractErrorMessage(responseData);

  if (message.trim().isNotEmpty) {
    return Exception(message);
  }

  return Exception(error.message ?? 'Erro de conexão.');
}

Response<dynamic> _ensureSuccessResponse(Response<dynamic> response) {
  if (_isSuccessStatus(response.statusCode)) {
    return response;
  }

  final statusCode = response.statusCode;
  final message = _extractErrorMessage(response.data);

  if (statusCode == 401) {
    throw Exception('Sessão expirada. Faça login novamente.');
  }

  if (statusCode == 403) {
    throw Exception('Acesso negado.');
  }

  if (statusCode == 404) {
    throw Exception('Informação não encontrada.');
  }

  if (statusCode != null && statusCode >= 500) {
    throw Exception('Servidor indisponível. Tente novamente em instantes.');
  }

  throw Exception(message);
}

Future<Response<dynamic>> safeGet(
  Dio dio,
  String path, {
  Map<String, dynamic>? queryParameters,
}) async {
  try {
    final response = await dio.get(
      path,
      queryParameters: queryParameters,
    );

    return _ensureSuccessResponse(response);
  } on TimeoutException {
    throw Exception('Tempo de conexão esgotado.');
  } on DioException catch (e) {
    throw _buildDioExceptionMessage(e);
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }

    throw Exception('Erro inesperado: $e');
  }
}

Future<Response<dynamic>> safePost(
  Dio dio,
  String path, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
}) async {
  try {
    final response = await dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );

    return _ensureSuccessResponse(response);
  } on TimeoutException {
    throw Exception('Tempo de conexão esgotado.');
  } on DioException catch (e) {
    throw _buildDioExceptionMessage(e);
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }

    throw Exception('Erro inesperado: $e');
  }
}

Future<Response<dynamic>> safePut(
  Dio dio,
  String path, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
}) async {
  try {
    final response = await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );

    return _ensureSuccessResponse(response);
  } on TimeoutException {
    throw Exception('Tempo de conexão esgotado.');
  } on DioException catch (e) {
    throw _buildDioExceptionMessage(e);
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }

    throw Exception('Erro inesperado: $e');
  }
}

Future<Response<dynamic>> safeDelete(
  Dio dio,
  String path, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
}) async {
  try {
    final response = await dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
    );

    return _ensureSuccessResponse(response);
  } on TimeoutException {
    throw Exception('Tempo de conexão esgotado.');
  } on DioException catch (e) {
    throw _buildDioExceptionMessage(e);
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }

    throw Exception('Erro inesperado: $e');
  }
}
