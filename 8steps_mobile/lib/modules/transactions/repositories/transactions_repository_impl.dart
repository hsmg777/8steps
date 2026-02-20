import '../../../services/transactions/transactions_service.dart';
import '../models/app_transaction.dart';
import 'transactions_repository.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._service);

  final TransactionsService _service;

  @override
  Future<TransactionsPage> getTransactions({
    required DateTime from,
    required DateTime to,
    String? type,
    String? accountId,
    String? categoryId,
    int page = 1,
  }) {
    return _service.getTransactions(
      from: from,
      to: to,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      page: page,
    );
  }

  @override
  Future<AppTransaction> createTransaction({
    required String type,
    required double amount,
    String? categoryId,
    required DateTime occurredAt,
    String? accountId,
    String? note,
  }) {
    return _service.createTransaction(
      type: type,
      amount: amount,
      categoryId: categoryId,
      occurredAt: occurredAt,
      accountId: accountId,
      note: note,
    );
  }

  @override
  Future<AppTransaction> getTransactionById(String id) {
    return _service.getTransactionById(id);
  }

  @override
  Future<AppTransaction> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? accountId,
    String? categoryId,
    DateTime? occurredAt,
    String? note,
  }) {
    return _service.updateTransaction(
      id: id,
      type: type,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      occurredAt: occurredAt,
      note: note,
    );
  }

  @override
  Future<void> deleteTransaction(String id) {
    return _service.deleteTransaction(id);
  }
}
