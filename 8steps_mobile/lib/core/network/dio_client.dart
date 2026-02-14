import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_storage_keys.dart';

class DioClient {
  static Dio create({
    required String baseUrl,
    required FlutterSecureStorage storage,
    required Future<void> Function() onUnauthorized,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: AuthStorageKeys.accessToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await storage.delete(key: AuthStorageKeys.accessToken);
            await storage.delete(key: AuthStorageKeys.refreshToken);
            await storage.delete(key: AuthStorageKeys.userId);
            await storage.delete(key: AuthStorageKeys.userEmail);
            await storage.delete(key: AuthStorageKeys.userRole);
            await onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
