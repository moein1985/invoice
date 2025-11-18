import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../constants/env.dart';
import '../constants/hive_boxes.dart';

class ApiClient {
  final Dio _dio;

  Dio get dio => _dio;

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

    // Attach auth token from Hive (if exists)
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final authBox = Hive.box(HiveBoxes.auth);
          final token = authBox.get('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        handler.next(options);
      },
    ));

    return ApiClient._internal(dio);
  }
}
