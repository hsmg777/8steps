import 'package:dio/dio.dart';

import '../../modules/recurrings/models/recurrent_item.dart';

class RecurringsService {
  RecurringsService(this._dio);

  final Dio _dio;

  Future<List<RecurrentExpense>> getRecurringExpenses() async {
    final response = await _dio.get('/recurrings/expenses');
    final raw = _extractList(response.data, 'expenses');
    return raw.map(RecurrentExpense.fromJson).toList();
  }

  Future<RecurrentExpense> createRecurringExpense({
    required String name,
    required double amount,
    required String frequency,
    required DateTime startAt,
    required String method,
    String? accountId,
    String? cardId,
    String? categoryId,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/recurrings/expenses',
      data: {
        'name': name,
        'amount': amount,
        'frequency': frequency,
        'startAt': startAt.toUtc().toIso8601String(),
        'method': method,
        if (accountId != null) 'accountId': accountId,
        if (cardId != null) 'cardId': cardId,
        if (categoryId != null) 'categoryId': categoryId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    final json = _extractItem(response.data, 'expense');
    if (json == null) {
      throw const FormatException(
          'Respuesta inválida al crear gasto recurrente');
    }
    return RecurrentExpense.fromJson(json);
  }

  Future<void> updateRecurringExpense({
    required String id,
    String? name,
    double? amount,
    String? frequency,
    DateTime? startAt,
    String? method,
    String? accountId,
    String? cardId,
    String? categoryId,
    String? note,
    String? status,
  }) async {
    await _dio.patch(
      '/recurrings/expenses/$id',
      data: {
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (frequency != null) 'frequency': frequency,
        if (startAt != null) 'startAt': startAt.toUtc().toIso8601String(),
        if (method != null) 'method': method,
        if (accountId != null) 'accountId': accountId,
        if (cardId != null) 'cardId': cardId,
        if (categoryId != null) 'categoryId': categoryId,
        if (note != null) 'note': note,
        if (status != null) 'status': status,
      },
    );
  }

  Future<void> deleteRecurringExpense(String id) async {
    await _dio.delete('/recurrings/expenses/$id');
  }

  Future<List<RecurrentIncome>> getRecurringIncomes() async {
    final response = await _dio.get('/recurrings/incomes');
    final raw = _extractList(response.data, 'incomes');
    return raw.map(RecurrentIncome.fromJson).toList();
  }

  Future<RecurrentIncome> createRecurringIncome({
    required String name,
    required double amount,
    required String frequency,
    required DateTime startAt,
    required String accountId,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/recurrings/incomes',
      data: {
        'name': name,
        'amount': amount,
        'frequency': frequency,
        'startAt': startAt.toUtc().toIso8601String(),
        'accountId': accountId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    final json = _extractItem(response.data, 'income');
    if (json == null) {
      throw const FormatException(
          'Respuesta inválida al crear ingreso recurrente');
    }
    return RecurrentIncome.fromJson(json);
  }

  Future<void> updateRecurringIncome({
    required String id,
    String? name,
    double? amount,
    String? frequency,
    DateTime? startAt,
    String? accountId,
    String? note,
    String? status,
  }) async {
    await _dio.patch(
      '/recurrings/incomes/$id',
      data: {
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (frequency != null) 'frequency': frequency,
        if (startAt != null) 'startAt': startAt.toUtc().toIso8601String(),
        if (accountId != null) 'accountId': accountId,
        if (note != null) 'note': note,
        if (status != null) 'status': status,
      },
    );
  }

  Future<void> deleteRecurringIncome(String id) async {
    await _dio.delete('/recurrings/incomes/$id');
  }

  List<Map<String, dynamic>> _extractList(dynamic body, String key) {
    final raw = _findList(body, key) ?? const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic>? _extractItem(Map<String, dynamic>? body, String key) {
    if (body == null) return null;
    final direct = body[key];
    if (direct is Map<String, dynamic>) return direct;
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) return nested;
      if (data.containsKey('id')) return data;
    }
    for (final value in body.values) {
      if (value is Map<String, dynamic> && value.containsKey('id')) {
        return value;
      }
    }
    if (body.containsKey('id')) return body;
    return null;
  }

  List<dynamic>? _findList(dynamic body, String key) {
    if (body is List<dynamic>) return body;
    if (body is! Map<String, dynamic>) return null;

    final direct = body[key];
    if (direct is List<dynamic>) return direct;

    const commonKeys = ['items', 'data', 'results', 'records'];
    for (final candidateKey in commonKeys) {
      final candidate = body[candidateKey];
      if (candidate is List<dynamic>) return candidate;
      if (candidate is Map<String, dynamic>) {
        final nestedDirect = candidate[key];
        if (nestedDirect is List<dynamic>) return nestedDirect;
        final nestedList = _findList(candidate, key);
        if (nestedList != null) return nestedList;
      }
    }

    for (final value in body.values) {
      if (value is List<dynamic>) {
        final firstMap = value.whereType<Map<String, dynamic>>().isNotEmpty;
        if (firstMap) return value;
      }
      if (value is Map<String, dynamic>) {
        final nested = _findList(value, key);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}
