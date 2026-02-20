import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_storage_keys.dart';

class DioClient {
  static bool _unauthorizedScheduled = false;

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
          if (kDebugMode) {
            debugPrint(
              '[DIO][REQ] ${options.method} ${options.baseUrl}${options.path}',
            );
            debugPrint('[DIO][REQ][DATA] ${options.data}');
          }
          final token = await storage.read(key: AuthStorageKeys.accessToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[DIO][RES] ${response.statusCode} '
              '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            );
            debugPrint('[DIO][RES][DATA] ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint(
              '[DIO][ERR] ${error.response?.statusCode ?? '-'} '
              '${error.requestOptions.baseUrl}${error.requestOptions.path}',
            );
            debugPrint('[DIO][ERR][DATA] ${error.response?.data}');
          }
          if (error.response?.statusCode == 401) {
            await storage.delete(key: AuthStorageKeys.accessToken);
            await storage.delete(key: AuthStorageKeys.refreshToken);
            await storage.delete(key: AuthStorageKeys.userId);
            await storage.delete(key: AuthStorageKeys.userEmail);
            await storage.delete(key: AuthStorageKeys.userRole);
            await storage.delete(key: AuthStorageKeys.userFirstName);
            await storage.delete(key: AuthStorageKeys.userLastName);
            _scheduleUnauthorized(onUnauthorized);
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static void _scheduleUnauthorized(Future<void> Function() onUnauthorized) {
    if (_unauthorizedScheduled) return;
    _unauthorizedScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        onUnauthorized().whenComplete(() {
          _unauthorizedScheduled = false;
        }),
      );
    });
  }
}
