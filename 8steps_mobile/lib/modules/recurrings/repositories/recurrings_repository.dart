import '../models/recurrent_item.dart';

abstract class RecurringsRepository {
  Future<List<RecurrentExpense>> getRecurringExpenses();
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
  });
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
  });
  Future<void> deleteRecurringExpense(String id);

  Future<List<RecurrentIncome>> getRecurringIncomes();
  Future<RecurrentIncome> createRecurringIncome({
    required String name,
    required double amount,
    required String frequency,
    required DateTime startAt,
    required String accountId,
    String? note,
  });
  Future<void> updateRecurringIncome({
    required String id,
    String? name,
    double? amount,
    String? frequency,
    DateTime? startAt,
    String? accountId,
    String? note,
    String? status,
  });
  Future<void> deleteRecurringIncome(String id);
}
