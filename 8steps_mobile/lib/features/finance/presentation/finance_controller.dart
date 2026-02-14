import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/app_database.dart';
import '../../../data/repositories/finance_repository.dart';

class FinanceController {
  FinanceController({required FinanceRepository repository, required Uuid uuid})
      : _repository = repository,
        _uuid = uuid;

  final FinanceRepository _repository;
  final Uuid _uuid;

  Future<void> createTransaction({
    required String type,
    required int amountCents,
    required DateTime date,
    required String categoryId,
    String? note,
  }) async {
    await _repository.createTransaction(
      TransactionsCompanion.insert(
        id: _uuid.v4(),
        type: type,
        amountCents: amountCents,
        date: date,
        categoryId: categoryId,
        note: Value(note),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateTransaction({
    required String id,
    required String type,
    required int amountCents,
    required DateTime date,
    required String categoryId,
    String? note,
  }) async {
    await _repository.updateTransaction(
      id,
      TransactionsCompanion(
        type: Value(type),
        amountCents: Value(amountCents),
        date: Value(date),
        categoryId: Value(categoryId),
        note: Value(note),
      ),
    );
  }

  Future<void> deleteTransaction(String id) =>
      _repository.deleteTransaction(id);

  Future<void> createFixedExpense({
    required String name,
    required int amountCents,
    required int dayOfMonth,
    required String categoryId,
    required bool isActive,
  }) async {
    await _repository.createFixedExpense(
      FixedExpensesCompanion.insert(
        id: _uuid.v4(),
        name: name,
        amountCents: amountCents,
        dayOfMonth: dayOfMonth,
        categoryId: categoryId,
        isActive: Value(isActive),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateFixedExpense({
    required String id,
    required String name,
    required int amountCents,
    required int dayOfMonth,
    required String categoryId,
    required bool isActive,
  }) {
    return _repository.updateFixedExpense(
      id,
      FixedExpensesCompanion(
        name: Value(name),
        amountCents: Value(amountCents),
        dayOfMonth: Value(dayOfMonth),
        categoryId: Value(categoryId),
        isActive: Value(isActive),
      ),
    );
  }

  Future<void> deleteFixedExpense(String id) =>
      _repository.deleteFixedExpense(id);

  Future<void> createInstallment({
    required String name,
    required int totalAmountCents,
    required int installmentsCount,
    required int installmentsPaid,
    required DateTime startDate,
    required String categoryId,
    required bool isActive,
  }) async {
    await _repository.createInstallment(
      InstallmentsCompanion.insert(
        id: _uuid.v4(),
        name: name,
        totalAmountCents: totalAmountCents,
        installmentsCount: installmentsCount,
        installmentsPaid: Value(installmentsPaid),
        startDate: startDate,
        categoryId: categoryId,
        isActive: Value(isActive),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateInstallment({
    required String id,
    required String name,
    required int totalAmountCents,
    required int installmentsCount,
    required int installmentsPaid,
    required DateTime startDate,
    required String categoryId,
    required bool isActive,
  }) {
    return _repository.updateInstallment(
      id,
      InstallmentsCompanion(
        name: Value(name),
        totalAmountCents: Value(totalAmountCents),
        installmentsCount: Value(installmentsCount),
        installmentsPaid: Value(installmentsPaid),
        startDate: Value(startDate),
        categoryId: Value(categoryId),
        isActive: Value(isActive),
      ),
    );
  }

  Future<void> deleteInstallment(String id) =>
      _repository.deleteInstallment(id);
}
