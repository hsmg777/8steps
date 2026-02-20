import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal_models.dart';
import '../repositories/goals_repository.dart';

class GoalsState {
  const GoalsState({
    this.loading = false,
    this.saving = false,
    this.goals = const [],
    this.selectedGoal,
    this.recommendation,
    this.contributions = const [],
    this.errorMessage,
  });

  final bool loading;
  final bool saving;
  final List<Goal> goals;
  final GoalDetail? selectedGoal;
  final GoalRecommendationResult? recommendation;
  final List<GoalContribution> contributions;
  final String? errorMessage;

  GoalsState copyWith({
    bool? loading,
    bool? saving,
    List<Goal>? goals,
    GoalDetail? selectedGoal,
    bool clearSelectedGoal = false,
    GoalRecommendationResult? recommendation,
    bool clearRecommendation = false,
    List<GoalContribution>? contributions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoalsState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      goals: goals ?? this.goals,
      selectedGoal:
          clearSelectedGoal ? null : (selectedGoal ?? this.selectedGoal),
      recommendation:
          clearRecommendation ? null : (recommendation ?? this.recommendation),
      contributions: contributions ?? this.contributions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class GoalsViewModel extends StateNotifier<GoalsState> {
  GoalsViewModel(this._repo) : super(const GoalsState());

  final GoalsRepository _repo;

  Future<void> loadGoals() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final goals = await _repo.getGoals();
      state = state.copyWith(loading: false, goals: goals);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: _mapUnknownError(e, fallback: 'No se pudo cargar metas'),
      );
    }
  }

  Future<void> loadGoalDetail(String goalId) async {
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearRecommendation: true,
    );
    try {
      final goalDetail = await _repo.getGoalById(goalId);
      final contributions =
          await _repo.getContributions(goalId: goalId, page: 1);
      GoalRecommendationResult? recommendation;
      String? firstError;
      try {
        recommendation = await _repo.getRecommendation(goalId: goalId);
      } on DioException catch (e) {
        firstError = _mapError(e);
      } catch (e) {
        firstError = _mapUnknownError(
          e,
          fallback: 'No se pudo cargar recomendación',
        );
      }
      state = state.copyWith(
        loading: false,
        selectedGoal: goalDetail,
        contributions: contributions,
        recommendation: recommendation,
        errorMessage: firstError,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: _mapUnknownError(
          e,
          fallback: 'No se pudo cargar detalle de la meta',
        ),
      );
    }
  }

  Future<Goal?> createGoal({
    required String name,
    required String type,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      final goal = await _repo.createGoal(
        name: name,
        type: type,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );
      await loadGoals();
      state = state.copyWith(saving: false);
      return goal;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return null;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(e, fallback: 'No se pudo crear meta'),
      );
      return null;
    }
  }

  Future<bool> updateGoal({
    required String id,
    String? name,
    String? type,
    double? targetAmount,
    DateTime? targetDate,
    String? status,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.updateGoal(
        id: id,
        name: name,
        type: type,
        targetAmount: targetAmount,
        targetDate: targetDate,
        status: status,
      );
      await loadGoals();
      if (state.selectedGoal?.goal.id == id) {
        await loadGoalDetail(id);
      }
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
          fallback: 'No se pudo actualizar meta',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteGoal(String goalId) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.deleteGoal(goalId);
      await loadGoals();
      final clearSelected = state.selectedGoal?.goal.id == goalId;
      state = state.copyWith(
        saving: false,
        clearSelectedGoal: clearSelected,
        contributions: clearSelected ? const [] : state.contributions,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: _mapUnknownError(e, fallback: 'No se pudo eliminar meta'),
      );
      return false;
    }
  }

  Future<bool> createContribution({
    required String goalId,
    required String fromAccountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.createContribution(
        goalId: goalId,
        fromAccountId: fromAccountId,
        amount: amount,
        date: date,
        note: note,
      );
      await loadGoals();
      await loadGoalDetail(goalId);
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
          fallback: 'No se pudo registrar aporte',
        ),
      );
      return false;
    }
  }

  Future<bool> upsertAutoContribution({
    required String goalId,
    required String fromAccountId,
    required double amount,
    required String frequency,
    int? dayOfMonth,
    DateTime? nextRunDate,
    required bool enabled,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.upsertAutoContribution(
        goalId: goalId,
        fromAccountId: fromAccountId,
        amount: amount,
        frequency: frequency,
        dayOfMonth: dayOfMonth,
        nextRunDate: nextRunDate,
        enabled: enabled,
      );
      await loadGoals();
      await loadGoalDetail(goalId);
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
          fallback: 'No se pudo configurar aporte automático',
        ),
      );
      return false;
    }
  }

  Future<bool> updateAutoContribution({
    required String goalId,
    required String autoId,
    String? fromAccountId,
    double? amount,
    String? frequency,
    int? dayOfMonth,
    DateTime? nextRunDate,
    bool? enabled,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.updateAutoContribution(
        goalId: goalId,
        autoId: autoId,
        fromAccountId: fromAccountId,
        amount: amount,
        frequency: frequency,
        dayOfMonth: dayOfMonth,
        nextRunDate: nextRunDate,
        enabled: enabled,
      );
      await loadGoals();
      await loadGoalDetail(goalId);
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
          fallback: 'No se pudo actualizar aporte automático',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteAutoContribution({
    required String goalId,
    required String autoId,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.deleteAutoContribution(goalId: goalId, autoId: autoId);
      await loadGoals();
      await loadGoalDetail(goalId);
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
          fallback: 'No se pudo eliminar aporte automático',
        ),
      );
      return false;
    }
  }

  String _mapError(DioException e) {
    final message = _extractApiMessage(e.response?.data);
    if (message != null && message.isNotEmpty) return message;

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

  String? _extractApiMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) return data;
    if (data is! Map<String, dynamic>) return null;

    final candidates = [
      data['message'],
      data['error'],
      data['detail'],
      data['msg'],
    ];

    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) return value;
    }

    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String && first.trim().isNotEmpty) return first;
      if (first is Map<String, dynamic>) {
        final nested = first['message'] ?? first['error'] ?? first['msg'];
        if (nested is String && nested.trim().isNotEmpty) return nested;
      }
    }

    return null;
  }

  String _mapUnknownError(Object error, {required String fallback}) {
    final raw = error.toString().trim();
    if (raw.isNotEmpty && raw != 'Exception') return raw;
    return fallback;
  }
}
