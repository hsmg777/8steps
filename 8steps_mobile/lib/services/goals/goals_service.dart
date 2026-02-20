import 'package:dio/dio.dart';

import '../../modules/goals/models/goal_models.dart';

class GoalsService {
  GoalsService(this._dio);

  final Dio _dio;

  Future<List<Goal>> getGoals() async {
    final response = await _dio.get('/goals');
    final raw = _extractList(response.data, 'goals');
    return raw.whereType<Map<String, dynamic>>().map(Goal.fromJson).toList();
  }

  Future<Goal> createGoal({
    required String name,
    required String type,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/goals',
      data: {
        'name': name,
        'type': type,
        'targetAmount': targetAmount,
        'targetDate': _dateOnly(targetDate),
      },
    );

    final json = _extractItem(response.data, 'goal');
    if (json == null) {
      throw const FormatException('Respuesta inválida al crear meta');
    }
    return Goal.fromJson(json);
  }

  Future<GoalDetail> getGoalById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/goals/$id');
    final body = response.data;
    if (body == null) {
      throw const FormatException('Respuesta inválida de detalle de meta');
    }

    final goalJson = _extractItem(body, 'goal') ?? body;
    final autoJson = body['autoContribution'] is Map<String, dynamic>
        ? body['autoContribution'] as Map<String, dynamic>
        : (body['auto_contribution'] is Map<String, dynamic>
            ? body['auto_contribution'] as Map<String, dynamic>
            : null);

    return GoalDetail(
      goal: Goal.fromJson(goalJson),
      autoContribution:
          autoJson == null ? null : GoalAutoContribution.fromJson(autoJson),
    );
  }

  Future<void> updateGoal({
    required String id,
    String? name,
    String? type,
    double? targetAmount,
    DateTime? targetDate,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (targetAmount != null) 'targetAmount': targetAmount,
      if (targetDate != null) 'targetDate': _dateOnly(targetDate),
      if (status != null) 'status': status,
    };
    await _dio.patch('/goals/$id', data: payload);
  }

  Future<void> deleteGoal(String id) async {
    await _dio.delete('/goals/$id');
  }

  Future<GoalRecommendationResult> getRecommendation({
    required String goalId,
    DateTime? asOf,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/goals/$goalId/recommendation',
      queryParameters: {
        if (asOf != null) 'as_of': _dateOnly(asOf),
      },
    );

    final body = response.data;
    if (body == null) {
      throw const FormatException('Respuesta inválida de recomendación');
    }
    return GoalRecommendationResult.fromJson(body);
  }

  Future<List<GoalContribution>> getContributions({
    required String goalId,
    int page = 1,
  }) async {
    final response = await _dio.get(
      '/goals/$goalId/contributions',
      queryParameters: {'page': page},
    );
    final raw = _extractList(response.data, 'contributions');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(GoalContribution.fromJson)
        .toList();
  }

  Future<void> createContribution({
    required String goalId,
    required String fromAccountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await _dio.post(
      '/goals/$goalId/contributions',
      data: {
        'fromAccountId': fromAccountId,
        'amount': amount,
        'date': _dateOnly(date),
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  Future<GoalAutoContribution> upsertAutoContribution({
    required String goalId,
    required String fromAccountId,
    required double amount,
    required String frequency,
    int? dayOfMonth,
    DateTime? nextRunDate,
    required bool enabled,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/goals/$goalId/auto-contributions',
      data: {
        'fromAccountId': fromAccountId,
        'amount': amount,
        'frequency': frequency,
        if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
        if (nextRunDate != null) 'nextRunDate': _dateOnly(nextRunDate),
        'enabled': enabled,
      },
    );

    final json = _extractItem(response.data, 'autoContribution') ??
        _extractItem(response.data, 'auto_contribution');
    if (json == null) {
      throw const FormatException('Respuesta inválida de aporte automático');
    }
    return GoalAutoContribution.fromJson(json);
  }

  Future<void> updateAutoContribution({
    required String goalId,
    required String autoId,
    String? fromAccountId,
    double? amount,
    String? frequency,
    int? dayOfMonth,
    DateTime? nextRunDate,
    bool? enabled,
  }) async {
    await _dio.patch(
      '/goals/$goalId/auto-contributions/$autoId',
      data: {
        if (fromAccountId != null) 'fromAccountId': fromAccountId,
        if (amount != null) 'amount': amount,
        if (frequency != null) 'frequency': frequency,
        if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
        if (nextRunDate != null) 'nextRunDate': _dateOnly(nextRunDate),
        if (enabled != null) 'enabled': enabled,
      },
    );
  }

  Future<void> deleteAutoContribution({
    required String goalId,
    required String autoId,
  }) async {
    await _dio.delete('/goals/$goalId/auto-contributions/$autoId');
  }

  List<dynamic> _extractList(dynamic body, String key) {
    if (body is List<dynamic>) return body;
    if (body is! Map<String, dynamic>) return const [];

    final direct = body[key];
    if (direct is List<dynamic>) return direct;

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nested = data[key];
      if (nested is List<dynamic>) return nested;
    }

    return const [];
  }

  Map<String, dynamic>? _extractItem(dynamic body, String key) {
    if (body is! Map<String, dynamic>) return null;

    final direct = body[key];
    if (direct is Map<String, dynamic>) return direct;

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) return nested;
      if (data.containsKey('id')) return data;
    }

    if (body.containsKey('id')) return body;
    return null;
  }

  String _dateOnly(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
