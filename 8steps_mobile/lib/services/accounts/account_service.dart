import 'package:dio/dio.dart';

import '../../modules/accounts/models/app_account.dart';

class AccountService {
  AccountService(this._dio);

  final Dio _dio;

  Future<List<AppAccount>> getAccounts() async {
    final response = await _dio.get('/accounts');
    final body = response.data;

    final List<dynamic>? rawList = switch (body) {
      List<dynamic> v => v,
      Map<String, dynamic> v => (v['accounts'] as List<dynamic>?),
      _ => null,
    };

    if (rawList == null) {
      throw const FormatException('Respuesta inválida de accounts');
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(AppAccount.fromJson)
        .toList();
  }

  Future<AppAccount> createAccount({
    required String name,
    required double initialBalance,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/accounts',
      data: {
        'name': name,
        'initialBalance': initialBalance,
      },
    );

    final body = response.data;
    final accountJson = body?['account'] is Map<String, dynamic>
        ? body!['account'] as Map<String, dynamic>
        : body;

    if (accountJson == null) {
      throw const FormatException('Respuesta inválida al crear cuenta');
    }

    return AppAccount.fromJson(accountJson);
  }

  Future<AppAccount> getAccountById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/accounts/$id');

    final body = response.data;
    final accountJson = body?['account'] is Map<String, dynamic>
        ? body!['account'] as Map<String, dynamic>
        : body;

    if (accountJson == null) {
      throw const FormatException('Respuesta inválida de detalle de cuenta');
    }

    return AppAccount.fromJson(accountJson);
  }

  Future<AppAccount> updateAccount({
    required String id,
    String? name,
    String? status,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (status != null) payload['status'] = status;

    final response = await _dio.patch<Map<String, dynamic>>(
      '/accounts/$id',
      data: payload,
    );

    final body = response.data;
    final accountJson = body?['account'] is Map<String, dynamic>
        ? body!['account'] as Map<String, dynamic>
        : body;

    if (accountJson == null) {
      throw const FormatException('Respuesta inválida al actualizar cuenta');
    }

    return AppAccount.fromJson(accountJson);
  }

  Future<void> addAdjustment({
    required String id,
    required double amount,
    required String reason,
  }) async {
    await _dio.post(
      '/accounts/$id/adjustments',
      data: {
        'amount': amount,
        'reason': reason,
      },
    );
  }
}
