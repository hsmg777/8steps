import 'package:dio/dio.dart';

import '../../modules/categories/models/app_category.dart';
import '../../modules/categories/models/budget_models.dart';

class CategoriesService {
  CategoriesService(this._dio);

  final Dio _dio;

  Future<List<AppCategory>> getCategories() async {
    final response = await _dio.get('/categories');
    final raw = _extractList(response.data, 'categories');

    return raw
        .whereType<Map<String, dynamic>>()
        .map(AppCategory.fromJson)
        .toList();
  }

  Future<CategoryMutationResult> createCategory({
    required String name,
    required double monthlyBudget,
    String? month,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/categories',
      data: {
        'name': name,
        'monthlyBudget': monthlyBudget,
        if (month != null) 'month': month,
      },
    );
    final body = response.data;
    final json = _extractItem(response.data, 'category');
    final warningJson = body is Map<String, dynamic> ? body['warning'] : null;
    final warning = warningJson is Map<String, dynamic>
        ? CategoryWarning.fromJson(warningJson)
        : null;
    if (json == null) {
      // Algunos backends responden solo con message en 201. No bloqueamos el flujo.
      return CategoryMutationResult(
        category: AppCategory(
          id: '',
          name: name,
          monthlyBudget: monthlyBudget,
        ),
        warning: warning,
      );
    }
    return CategoryMutationResult(
      category: AppCategory.fromJson(json),
      warning: warning,
    );
  }

  Future<CategoryMutationResult> updateCategory({
    required String categoryId,
    String? name,
    double? monthlyBudget,
    String? month,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (monthlyBudget != null) payload['monthlyBudget'] = monthlyBudget;
    if (month != null) payload['month'] = month;

    final response = await _dio.patch<Map<String, dynamic>>(
      '/categories/$categoryId',
      data: payload,
    );
    final body = response.data;
    final json = _extractItem(response.data, 'category');
    final warningJson = body is Map<String, dynamic> ? body['warning'] : null;
    final warning = warningJson is Map<String, dynamic>
        ? CategoryWarning.fromJson(warningJson)
        : null;
    if (json == null) {
      // Evita error falso si PATCH responde solo metadata.
      return CategoryMutationResult(
        category: AppCategory(
          id: categoryId,
          name: name ?? 'Categoría',
          monthlyBudget: monthlyBudget ?? 0,
        ),
        warning: warning,
      );
    }
    return CategoryMutationResult(
      category: AppCategory.fromJson(json),
      warning: warning,
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    await _dio.delete('/categories/$categoryId');
  }

  Future<List<BudgetStatusItem>> getBudgetStatus(String month) async {
    final response =
        await _dio.get('/budgets/status', queryParameters: {'month': month});
    final raw = _extractList(response.data, 'status');

    return raw
        .whereType<Map<String, dynamic>>()
        .map(BudgetStatusItem.fromJson)
        .toList();
  }

  Future<List<BudgetAlertItem>> getBudgetAlerts(String month) async {
    final response =
        await _dio.get('/budgets/alerts', queryParameters: {'month': month});
    final raw = _extractList(response.data, 'alerts');

    return raw
        .whereType<Map<String, dynamic>>()
        .map(BudgetAlertItem.fromJson)
        .toList();
  }

  Future<BudgetSummary> getBudgetSummary(String month) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/budgets/summary',
      queryParameters: {'month': month},
    );
    final body = response.data;
    if (body == null) return BudgetSummary.empty;

    final json = body['summary'] is Map<String, dynamic>
        ? body['summary'] as Map<String, dynamic>
        : body;
    return BudgetSummary.fromJson(json);
  }

  Future<List<BudgetCarryover>> getCarryovers(String month) async {
    final response = await _dio
        .get('/budgets/carryovers', queryParameters: {'month': month});
    final raw = _extractList(response.data, 'carryovers');

    return raw
        .whereType<Map<String, dynamic>>()
        .map(BudgetCarryover.fromJson)
        .toList();
  }

  Future<BudgetAffordability> getBudgetAffordability(String month) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/budgets/affordability',
      queryParameters: {'month': month},
    );
    final body = response.data;
    if (body == null) return BudgetAffordability.empty;

    final json = body['affordability'] is Map<String, dynamic>
        ? body['affordability'] as Map<String, dynamic>
        : body;
    return BudgetAffordability.fromJson(json);
  }

  Future<List<MonthClosure>> getClosures({
    required String from,
    required String to,
  }) async {
    final response = await _dio.get(
      '/months/closures',
      queryParameters: {'from': from, 'to': to},
    );
    final raw = _extractList(response.data, 'closures');

    return raw
        .whereType<Map<String, dynamic>>()
        .map(MonthClosure.fromJson)
        .toList();
  }

  List<dynamic> _extractList(dynamic body, String preferredKey) {
    if (body is List<dynamic>) return body;
    if (body is! Map<String, dynamic>) return const [];

    const keys = [
      'categories',
      'status',
      'alerts',
      'carryovers',
      'closures',
      'items',
      'data',
      'results',
      'records',
    ];

    final direct = body[preferredKey];
    if (direct is List<dynamic>) return direct;

    for (final key in keys) {
      final value = body[key];
      if (value is List<dynamic>) return value;
      if (value is Map<String, dynamic>) {
        final nestedPreferred = value[preferredKey];
        if (nestedPreferred is List<dynamic>) return nestedPreferred;
        for (final nested in keys) {
          final nestedValue = value[nested];
          if (nestedValue is List<dynamic>) return nestedValue;
        }
      }
    }

    for (final value in body.values) {
      if (value is List<dynamic>) return value;
    }
    return const [];
  }

  Map<String, dynamic>? _extractItem(dynamic body, String preferredKey) {
    if (body is! Map<String, dynamic>) return null;

    final direct = body[preferredKey];
    if (direct is Map<String, dynamic>) return direct;

    const keys = ['data', 'item', 'result', 'payload'];
    for (final key in keys) {
      final value = body[key];
      if (value is Map<String, dynamic>) {
        final nestedPreferred = value[preferredKey];
        if (nestedPreferred is Map<String, dynamic>) return nestedPreferred;
        if (value.containsKey('id') || value.containsKey('name')) return value;
      }
    }

    if (body.containsKey('id') || body.containsKey('name')) return body;
    return null;
  }
}
