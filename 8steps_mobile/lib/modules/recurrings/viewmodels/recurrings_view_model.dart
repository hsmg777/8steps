import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recurrent_item.dart';
import '../repositories/recurrings_repository.dart';

class RecurringsState {
  const RecurringsState({
    this.loading = false,
    this.saving = false,
    this.expenses = const [],
    this.incomes = const [],
    this.errorMessage,
  });

  final bool loading;
  final bool saving;
  final List<RecurrentExpense> expenses;
  final List<RecurrentIncome> incomes;
  final String? errorMessage;

  RecurringsState copyWith({
    bool? loading,
    bool? saving,
    List<RecurrentExpense>? expenses,
    List<RecurrentIncome>? incomes,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecurringsState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RecurringsViewModel extends StateNotifier<RecurringsState> {
  RecurringsViewModel(this._repo) : super(const RecurringsState());

  final RecurringsRepository _repo;

  Future<void> loadAll() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      List<RecurrentExpense> expenses = state.expenses;
      List<RecurrentIncome> incomes = state.incomes;
      String? error;

      try {
        expenses = await _repo.getRecurringExpenses();
      } on DioException catch (e) {
        error = _mapError(e);
      } catch (e) {
        error = _mapUnknownError(
          e,
          fallback: 'No se pudo cargar gastos recurrentes',
        );
      }

      try {
        incomes = await _repo.getRecurringIncomes();
      } on DioException catch (e) {
        error = error ?? _mapError(e);
      } catch (e) {
        error = error ??
            _mapUnknownError(
              e,
              fallback: 'No se pudo cargar ingresos recurrentes',
            );
      }

      state = state.copyWith(
        loading: false,
        expenses: expenses,
        incomes: incomes,
        errorMessage: error,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: _mapUnknownError(
          e,
          fallback: 'No se pudo cargar recurrentes',
        ),
      );
    }
  }

  Future<bool> createExpense({
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
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.createRecurringExpense(
        name: name,
        amount: amount,
        frequency: frequency,
        startAt: startAt,
        method: method,
        accountId: accountId,
        cardId: cardId,
        categoryId: categoryId,
        note: note,
      );
      await loadAll();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(
          e,
          fallback: 'No se pudo crear gasto recurrente',
        ),
      );
      return false;
    }
  }

  Future<bool> updateExpense({
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
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.updateRecurringExpense(
        id: id,
        name: name,
        amount: amount,
        frequency: frequency,
        startAt: startAt,
        method: method,
        accountId: accountId,
        cardId: cardId,
        categoryId: categoryId,
        note: note,
        status: status,
      );
      await loadAll();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(
          e,
          fallback: 'No se pudo actualizar gasto recurrente',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.deleteRecurringExpense(id);
      await loadAll();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(
          e,
          fallback: 'No se pudo eliminar gasto recurrente',
        ),
      );
      return false;
    }
  }

  Future<bool> createIncome({
    required String name,
    required double amount,
    required String frequency,
    required DateTime startAt,
    required String accountId,
    String? note,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.createRecurringIncome(
        name: name,
        amount: amount,
        frequency: frequency,
        startAt: startAt,
        accountId: accountId,
        note: note,
      );
      await loadAll();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(
          e,
          fallback: 'No se pudo crear ingreso recurrente',
        ),
      );
      return false;
    }
  }

  Future<bool> updateIncome({
    required String id,
    String? name,
    double? amount,
    String? frequency,
    DateTime? startAt,
    String? accountId,
    String? note,
    String? status,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.updateRecurringIncome(
        id: id,
        name: name,
        amount: amount,
        frequency: frequency,
        startAt: startAt,
        accountId: accountId,
        note: note,
        status: status,
      );
      await loadAll();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(
          e,
          fallback: 'No se pudo actualizar ingreso recurrente',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteIncome(String id) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.deleteRecurringIncome(id);
      await loadAll();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(
          e,
          fallback: 'No se pudo eliminar ingreso recurrente',
        ),
      );
      return false;
    }
  }

  String _mapError(DioException e) {
    final data = e.response?.data;
    final message = _extractApiMessage(data);
    if (message != null && message.isNotEmpty) {
      if (message.contains('<!DOCTYPE html') || message.contains('<html')) {
        return 'La API devolvió HTML. Revisa la ruta /api/v1.';
      }
      return message;
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'No se pudo conectar';
    }

    final status = e.response?.statusCode;
    if (status != null) {
      return 'Error del servidor (HTTP $status)';
    }

    return 'Ocurrió un error';
  }

  String _mapUnknownError(
    Object error, {
    required String fallback,
  }) {
    if (error is FormatException) {
      final message = error.message.toString();
      if (message.trim().isNotEmpty) return message;
    }
    final raw = error.toString().trim();
    if (raw.isNotEmpty && raw != 'Exception') return raw;
    return fallback;
  }

  String? _extractApiMessage(dynamic data) {
    if (data is String) return data;
    if (data is! Map<String, dynamic>) return null;

    final directMessage = data['message'];
    if (directMessage is String && directMessage.trim().isNotEmpty) {
      return directMessage;
    }
    final error = data['error'];
    if (error is String && error.trim().isNotEmpty) return error;
    if (error is Map<String, dynamic>) {
      final nested = error['message'];
      if (nested is String && nested.trim().isNotEmpty) return nested;
    }
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
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
