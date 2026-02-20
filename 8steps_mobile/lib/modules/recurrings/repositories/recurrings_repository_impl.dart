import '../../../services/recurrings/recurrings_service.dart';
import '../models/recurrent_item.dart';
import 'recurrings_repository.dart';

class RecurringsRepositoryImpl implements RecurringsRepository {
  RecurringsRepositoryImpl(this._service);

  final RecurringsService _service;

  @override
  Future<List<RecurrentExpense>> getRecurringExpenses() {
    return _service.getRecurringExpenses();
  }

  @override
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
  }) {
    return _service.createRecurringExpense(
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
  }

  @override
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
  }) {
    return _service.updateRecurringExpense(
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
  }

  @override
  Future<void> deleteRecurringExpense(String id) {
    return _service.deleteRecurringExpense(id);
  }

  @override
  Future<List<RecurrentIncome>> getRecurringIncomes() {
    return _service.getRecurringIncomes();
  }

  @override
  Future<RecurrentIncome> createRecurringIncome({
    required String name,
    required double amount,
    required String frequency,
    required DateTime startAt,
    required String accountId,
    String? note,
  }) {
    return _service.createRecurringIncome(
      name: name,
      amount: amount,
      frequency: frequency,
      startAt: startAt,
      accountId: accountId,
      note: note,
    );
  }

  @override
  Future<void> updateRecurringIncome({
    required String id,
    String? name,
    double? amount,
    String? frequency,
    DateTime? startAt,
    String? accountId,
    String? note,
    String? status,
  }) {
    return _service.updateRecurringIncome(
      id: id,
      name: name,
      amount: amount,
      frequency: frequency,
      startAt: startAt,
      accountId: accountId,
      note: note,
      status: status,
    );
  }

  @override
  Future<void> deleteRecurringIncome(String id) {
    return _service.deleteRecurringIncome(id);
  }
}
