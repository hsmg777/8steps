import '../models/goal_models.dart';

abstract class GoalsRepository {
  Future<List<Goal>> getGoals();

  Future<Goal> createGoal({
    required String name,
    required String type,
    required double targetAmount,
    required DateTime targetDate,
  });

  Future<GoalDetail> getGoalById(String id);

  Future<void> updateGoal({
    required String id,
    String? name,
    String? type,
    double? targetAmount,
    DateTime? targetDate,
    String? status,
  });

  Future<void> deleteGoal(String id);

  Future<GoalRecommendationResult> getRecommendation({
    required String goalId,
    DateTime? asOf,
  });

  Future<List<GoalContribution>> getContributions({
    required String goalId,
    int page,
  });

  Future<void> createContribution({
    required String goalId,
    required String fromAccountId,
    required double amount,
    required DateTime date,
    String? note,
  });

  Future<GoalAutoContribution> upsertAutoContribution({
    required String goalId,
    required String fromAccountId,
    required double amount,
    required String frequency,
    int? dayOfMonth,
    DateTime? nextRunDate,
    required bool enabled,
  });

  Future<void> updateAutoContribution({
    required String goalId,
    required String autoId,
    String? fromAccountId,
    double? amount,
    String? frequency,
    int? dayOfMonth,
    DateTime? nextRunDate,
    bool? enabled,
  });

  Future<void> deleteAutoContribution({
    required String goalId,
    required String autoId,
  });
}
