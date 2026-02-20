import 'package:dio/dio.dart';

import '../../modules/profile/models/app_subscription.dart';

class ProfileService {
  ProfileService(this._dio);

  final Dio _dio;

  Future<AppSubscription> meSubscription() async {
    final response = await _dio.get<Map<String, dynamic>>('/me/subscription');
    final subscriptionJson = response.data?['subscription'] as Map<String, dynamic>?;

    if (subscriptionJson == null) {
      throw const FormatException('Respuesta inválida de subscription');
    }

    return AppSubscription.fromJson(subscriptionJson);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/me/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
