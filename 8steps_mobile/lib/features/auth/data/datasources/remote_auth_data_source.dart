import 'package:dio/dio.dart';

import '../../domain/models/app_subscription.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/auth_session.dart';

class RemoteAuthDataSource {
  RemoteAuthDataSource(this._dio);

  final Dio _dio;

  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    final userJson = body['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw const FormatException('Respuesta inválida de register');
    }

    return AppUser.fromJson(userJson);
  }

  Future<AuthSession> login(
      {required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );

    final body = response.data ?? <String, dynamic>{};
    final userJson = body['user'] as Map<String, dynamic>?;
    final accessToken = body['accessToken'] as String?;
    final refreshToken = body['refreshToken'] as String?;

    if (userJson == null || accessToken == null || refreshToken == null) {
      throw const FormatException('Respuesta inválida de login');
    }

    return AuthSession(
      user: AppUser.fromJson(userJson),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<AppSubscription> meSubscription() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/v1/me/subscription');

    final body = response.data ?? <String, dynamic>{};
    final subscriptionJson = body['subscription'] as Map<String, dynamic>?;
    if (subscriptionJson == null) {
      throw const FormatException('Respuesta inválida de subscription');
    }

    return AppSubscription.fromJson(subscriptionJson);
  }
}
