import '../../../services/goals/goals_service.dart';
import '../models/goal_models.dart';
import 'goals_repository.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  GoalsRepositoryImpl(this._service);

  final GoalsService _service;

  @override
  Future<List<Goal>> getGoals() => _service.getGoals();

  @override
  Future<Goal> createGoal({
    required String name,
    required String type,
    required double targetAmount,
    required DateTime targetDate,
  }) {
    return _service.createGoal(
      name: name,
      type: type,
      targetAmount: targetAmount,
      targetDate: targetDate,
    );
  }

  @override
  Future<GoalDetail> getGoalById(String id) => _service.getGoalById(id);

  @override
  Future<void> updateGoal({
    required String id,
    String? name,
    String? type,
    double? targetAmount,
    DateTime? targetDate,
    String? status,
  }) {
    return _service.updateGoal(
      id: id,
      name: name,
      type: type,
      targetAmount: targetAmount,
      targetDate: targetDate,
      status: status,
    );
  }

  @override
  Future<void> deleteGoal(String id) => _service.deleteGoal(id);

  @override
  Future<GoalRecommendationResult> getRecommendation({
    required String goalId,
    DateTime? asOf,
  }) {
    return _service.getRecommendation(goalId: goalId, asOf: asOf);
  }

  @override
  Future<List<GoalContribution>> getContributions({
    required String goalId,
    int page = 1,
  }) {
    return _service.getContributions(goalId: goalId, page: page);
  }

  @override
  Future<void> createContribution({
    required String goalId,
    required String fromAccountId,
    required double amount,
    required DateTime date,
    String? note,
  }) {
    return _service.createContribution(
      goalId: goalId,
      fromAccountId: fromAccountId,
      amount: amount,
      date: date,
      note: note,
    );
  }

  @override
  Future<GoalAutoContribution> upsertAutoContribution({
    required String goalId,
    required String fromAccountId,
    required double amount,
    required String frequency,
    int? dayOfMonth,
    DateTime? nextRunDate,
    required bool enabled,
  }) {
    return _service.upsertAutoContribution(
      goalId: goalId,
      fromAccountId: fromAccountId,
      amount: amount,
      frequency: frequency,
      dayOfMonth: dayOfMonth,
      nextRunDate: nextRunDate,
      enabled: enabled,
    );
  }

  @override
  Future<void> updateAutoContribution({
    required String goalId,
    required String autoId,
    String? fromAccountId,
    double? amount,
    String? frequency,
    int? dayOfMonth,
    DateTime? nextRunDate,
    bool? enabled,
  }) {
    return _service.updateAutoContribution(
      goalId: goalId,
      autoId: autoId,
      fromAccountId: fromAccountId,
      amount: amount,
      frequency: frequency,
      dayOfMonth: dayOfMonth,
      nextRunDate: nextRunDate,
      enabled: enabled,
    );
  }

  @override
  Future<void> deleteAutoContribution({
    required String goalId,
    required String autoId,
  }) {
    return _service.deleteAutoContribution(goalId: goalId, autoId: autoId);
  }
}
