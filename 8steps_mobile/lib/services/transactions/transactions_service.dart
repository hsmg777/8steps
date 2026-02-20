import 'package:dio/dio.dart';

import '../../modules/transactions/models/app_transaction.dart';

class TransactionsService {
  TransactionsService(this._dio);

  final Dio _dio;

  Future<TransactionsPage> getTransactions({
    required DateTime from,
    required DateTime to,
    String? type,
    String? accountId,
    String? categoryId,
    int page = 1,
  }) async {
    final query = <String, dynamic>{
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      'page': page,
    };
    if (type != null) query['type'] = type;
    if (categoryId != null) query['category_id'] = categoryId;

    final response = accountId == null
        ? await _dio.get('/transactions', queryParameters: {
            ...query,
            if (accountId != null) 'account_id': accountId,
          })
        : await _dio.get('/accounts/$accountId/transactions',
            queryParameters: query);

    return TransactionsPage.fromJson(response.data);
  }

  Future<AppTransaction> createTransaction({
    required String type,
    required double amount,
    String? categoryId,
    required DateTime occurredAt,
    String? accountId,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/transactions',
      data: {
        'type': type,
        'amount': amount,
        if (categoryId != null) 'categoryId': categoryId,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        if (accountId != null) 'accountId': accountId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    final json = _extractTransactionJson(response.data);
    if (json == null) {
      throw const FormatException('Respuesta inválida al crear movimiento');
    }
    return AppTransaction.fromJson(json);
  }

  Future<AppTransaction> getTransactionById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/transactions/$id');
    final json = _extractTransactionJson(response.data);
    if (json == null) {
      throw const FormatException('Respuesta inválida de detalle');
    }
    return AppTransaction.fromJson(json);
  }

  Future<AppTransaction> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? accountId,
    String? categoryId,
    DateTime? occurredAt,
    String? note,
  }) async {
    final payload = <String, dynamic>{
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (accountId != null) 'accountId': accountId,
      if (categoryId != null) 'categoryId': categoryId,
      if (occurredAt != null)
        'occurredAt': occurredAt.toUtc().toIso8601String(),
      if (note != null) 'note': note,
    };

    final response = await _dio.patch<Map<String, dynamic>>(
      '/transactions/$id',
      data: payload,
    );

    final json = _extractTransactionJson(response.data);
    if (json == null) {
      throw const FormatException('Respuesta inválida al editar movimiento');
    }
    return AppTransaction.fromJson(json);
  }

  Future<void> deleteTransaction(String id) async {
    await _dio.delete('/transactions/$id');
  }

  Map<String, dynamic>? _extractTransactionJson(Map<String, dynamic>? body) {
    if (body == null) return null;

    const preferredKeys = ['transaction', 'movement', 'item', 'data', 'result'];
    for (final key in preferredKeys) {
      final value = body[key];
      if (value is Map<String, dynamic>) return value;
    }

    if (_looksLikeTransaction(body)) return body;

    for (final value in body.values) {
      if (value is Map<String, dynamic> && _looksLikeTransaction(value)) {
        return value;
      }
    }

    return null;
  }

  bool _looksLikeTransaction(Map<String, dynamic> map) {
    return map.containsKey('id') &&
        map.containsKey('amount') &&
        (map.containsKey('type') || map.containsKey('categoryId'));
  }
}
