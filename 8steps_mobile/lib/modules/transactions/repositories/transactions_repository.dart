import '../models/app_transaction.dart';

abstract class TransactionsRepository {
  Future<TransactionsPage> getTransactions({
    required DateTime from,
    required DateTime to,
    String? type,
    String? accountId,
    String? categoryId,
    int page = 1,
  });

  Future<AppTransaction> createTransaction({
    required String type,
    required double amount,
    String? categoryId,
    required DateTime occurredAt,
    String? accountId,
    String? note,
  });

  Future<AppTransaction> getTransactionById(String id);

  Future<AppTransaction> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? accountId,
    String? categoryId,
    DateTime? occurredAt,
    String? note,
  });

  Future<void> deleteTransaction(String id);
}
