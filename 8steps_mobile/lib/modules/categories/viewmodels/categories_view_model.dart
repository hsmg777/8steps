import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_category.dart';
import '../models/budget_models.dart';
import '../repositories/categories_repository.dart';

class CategoriesState {
  const CategoriesState({
    this.loading = false,
    this.saving = false,
    this.month = '',
    this.categories = const [],
    this.statuses = const [],
    this.alerts = const [],
    this.summary = BudgetSummary.empty,
    this.affordability = BudgetAffordability.empty,
    this.carryovers = const [],
    this.closures = const [],
    this.warning,
    this.errorMessage,
  });

  final bool loading;
  final bool saving;
  final String month;
  final List<AppCategory> categories;
  final List<BudgetStatusItem> statuses;
  final List<BudgetAlertItem> alerts;
  final BudgetSummary summary;
  final BudgetAffordability affordability;
  final List<BudgetCarryover> carryovers;
  final List<MonthClosure> closures;
  final CategoryWarning? warning;
  final String? errorMessage;

  CategoriesState copyWith({
    bool? loading,
    bool? saving,
    String? month,
    List<AppCategory>? categories,
    List<BudgetStatusItem>? statuses,
    List<BudgetAlertItem>? alerts,
    BudgetSummary? summary,
    BudgetAffordability? affordability,
    List<BudgetCarryover>? carryovers,
    List<MonthClosure>? closures,
    CategoryWarning? warning,
    String? errorMessage,
    bool clearError = false,
    bool clearWarning = false,
  }) {
    return CategoriesState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      month: month ?? this.month,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      alerts: alerts ?? this.alerts,
      summary: summary ?? this.summary,
      affordability: affordability ?? this.affordability,
      carryovers: carryovers ?? this.carryovers,
      closures: closures ?? this.closures,
      warning: clearWarning ? null : (warning ?? this.warning),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CategoriesViewModel extends StateNotifier<CategoriesState> {
  CategoriesViewModel(this._repo) : super(const CategoriesState());

  final CategoriesRepository _repo;

  Future<void> load(String month) async {
    state = state.copyWith(loading: true, month: month, clearError: true);
    try {
      final year = month.split('-').first;
      // Keep categories list, but reset month-bound metrics to avoid stale data.
      List<AppCategory> categories = state.categories;
      List<BudgetStatusItem> statuses = const [];
      List<BudgetAlertItem> alerts = const [];
      BudgetSummary summary = BudgetSummary.empty;
      BudgetAffordability affordability = BudgetAffordability.empty;
      List<BudgetCarryover> carryovers = const [];
      List<MonthClosure> closures = const [];
      String? firstError;

      try {
        categories = await _repo.getCategories();
      } on DioException catch (e) {
        firstError = _mapError(e);
      } catch (_) {}

      try {
        statuses = await _repo.getBudgetStatus(month);
      } on DioException catch (e) {
        firstError ??= _mapError(e);
      } catch (_) {}

      try {
        alerts = await _repo.getBudgetAlerts(month);
      } on DioException catch (e) {
        firstError ??= _mapError(e);
      } catch (_) {}

      try {
        summary = await _repo.getBudgetSummary(month);
      } on DioException catch (e) {
        firstError ??= _mapError(e);
      } catch (_) {}

      try {
        affordability = await _repo.getBudgetAffordability(month);
      } on DioException catch (e) {
        firstError ??= _mapError(e);
      } catch (_) {}

      try {
        carryovers = await _repo.getCarryovers(month);
      } on DioException catch (e) {
        firstError ??= _mapError(e);
      } catch (_) {}

      try {
        closures = await _repo.getClosures(from: '$year-01', to: '$year-12');
      } on DioException catch (e) {
        firstError ??= _mapError(e);
      } catch (_) {}

      state = state.copyWith(
        loading: false,
        month: month,
        categories: categories,
        statuses: statuses,
        alerts: alerts,
        summary: summary,
        affordability: affordability,
        carryovers: carryovers,
        closures: closures,
        errorMessage: firstError,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'No se pudo cargar categorías y presupuestos',
      );
    }
  }

  Future<bool> createCategory({
    required String name,
    required double monthlyBudget,
    String? month,
  }) async {
    state = state.copyWith(saving: true, clearError: true, clearWarning: true);
    try {
      final result = await _repo.createCategory(
        name: name,
        monthlyBudget: monthlyBudget,
        month: month,
      );
      await load(state.month);
      state = state.copyWith(saving: false, warning: result.warning);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(e, fallback: 'No se pudo crear'),
      );
      return false;
    }
  }

  Future<bool> updateCategory({
    required String categoryId,
    String? name,
    double? monthlyBudget,
    String? month,
  }) async {
    state = state.copyWith(saving: true, clearError: true, clearWarning: true);
    try {
      final result = await _repo.updateCategory(
        categoryId: categoryId,
        name: name,
        monthlyBudget: monthlyBudget,
        month: month,
      );
      await load(state.month);
      state = state.copyWith(saving: false, warning: result.warning);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(e, fallback: 'No se pudo actualizar'),
      );
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.deleteCategory(categoryId);
      await load(state.month);
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(e, fallback: 'No se pudo eliminar'),
      );
      return false;
    }
  }

  BudgetStatusItem? statusForCategory(String categoryId) {
    for (final item in state.statuses) {
      if (item.categoryId == categoryId) return item;
    }
    return null;
  }

  String _mapError(DioException e) {
    final data = e.response?.data;
    final msg = _extractApiMessage(data);
    if (msg != null && msg.isNotEmpty) {
      if (data is Map<String, dynamic>) {
        final month = data['month']?.toString();
        final remaining =
            data['remainingToBudget'] ?? data['remaining_to_budget'];
        if (month != null && remaining != null) {
          return '$msg (Mes: $month, restante: \$${_toMoney(remaining)})';
        }
      }
      return msg;
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'No se pudo conectar';
    }

    final status = e.response?.statusCode;
    if (status != null) return 'Error del servidor (HTTP $status)';
    return 'Ocurrió un error';
  }

  String _toMoney(dynamic value) {
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    return amount.toStringAsFixed(2);
  }

  String _mapUnknownError(Object error, {required String fallback}) {
    final raw = error.toString().trim();
    if (raw.isNotEmpty && raw != 'Exception') return raw;
    return fallback;
  }

  String? _extractApiMessage(dynamic data) {
    if (data is String) return data;
    if (data is! Map<String, dynamic>) return null;

    final direct = data['message'];
    if (direct is String && direct.trim().isNotEmpty) return direct;

    final error = data['error'];
    if (error is String && error.trim().isNotEmpty) return error;
    if (error is Map<String, dynamic>) {
      final nested = error['message'] ?? error['msg'];
      if (nested is String && nested.trim().isNotEmpty) return nested;
    }

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String && first.trim().isNotEmpty) return first;
      if (first is Map<String, dynamic>) {
        final nested = first['message'] ?? first['msg'] ?? first['error'];
        if (nested is String && nested.trim().isNotEmpty) return nested;
      }
    }
    return null;
  }
}
