import 'package:dio/dio.dart';

import '../constants/env.dart';

class ApiClient {
  final Dio _dio;
  static String? _authToken;

  Dio get dio => _dio;

  static void setToken(String? token) {
    _authToken = token;
  }

  static String? getToken() {
    return _authToken;
  }

  static bool get isLoggedIn => _authToken != null && _authToken!.isNotEmpty;

  ApiClient._internal(this._dio);

  factory ApiClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Attach auth token if exists
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = _authToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

    return ApiClient._internal(dio);
  }
}
