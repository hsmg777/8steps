import '../models/app_account.dart';

abstract class AccountsRepository {
  Future<List<AppAccount>> getAccounts();
  Future<AppAccount> createAccount({
    required String name,
    required double initialBalance,
  });
  Future<AppAccount> getAccountById(String id);
  Future<AppAccount> updateAccount({
    required String id,
    String? name,
    String? status,
  });
  Future<void> addAdjustment({
    required String id,
    required double amount,
    required String reason,
  });
}
