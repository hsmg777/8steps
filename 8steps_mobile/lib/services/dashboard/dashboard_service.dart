import 'package:dio/dio.dart';

import '../../modules/dashboard/models/dashboard_balance.dart';

class DashboardService {
  DashboardService(this._dio);

  final Dio _dio;

  Future<DashboardBalance> getBalance() async {
    final response = await _dio.get<Map<String, dynamic>>('/dashboard/balance');
    final body = response.data;
    if (body == null) return DashboardBalance.empty;

    final json = body['balance'] is Map<String, dynamic>
        ? body['balance'] as Map<String, dynamic>
        : body;
    return DashboardBalance.fromJson(json);
  }
}
