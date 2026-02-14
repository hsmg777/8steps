import '../local/app_database.dart';

class FinanceRepository {
  FinanceRepository(this._db);

  final AppDatabase _db;

  Future<void> createTransaction(TransactionsCompanion tx) =>
      _db.transactionsDao.create(tx);

  Future<void> updateTransaction(String id, TransactionsCompanion tx) =>
      _db.transactionsDao.updateById(id, tx);

  Future<void> deleteTransaction(String id) =>
      _db.transactionsDao.deleteById(id);

  Future<void> createFixedExpense(FixedExpensesCompanion item) =>
      _db.fixedExpensesDao.create(item);

  Future<void> updateFixedExpense(String id, FixedExpensesCompanion item) =>
      _db.fixedExpensesDao.updateById(id, item);

  Future<void> deleteFixedExpense(String id) =>
      _db.fixedExpensesDao.deleteById(id);

  Future<void> createInstallment(InstallmentsCompanion item) =>
      _db.installmentsDao.create(item);

  Future<void> updateInstallment(String id, InstallmentsCompanion item) =>
      _db.installmentsDao.updateById(id, item);

  Future<void> deleteInstallment(String id) =>
      _db.installmentsDao.deleteById(id);
}
