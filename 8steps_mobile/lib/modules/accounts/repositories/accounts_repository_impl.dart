import '../../../services/accounts/account_service.dart';
import '../models/app_account.dart';
import 'accounts_repository.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  AccountsRepositoryImpl(this._service);

  final AccountService _service;

  @override
  Future<List<AppAccount>> getAccounts() => _service.getAccounts();

  @override
  Future<AppAccount> createAccount({
    required String name,
    required double initialBalance,
  }) {
    return _service.createAccount(name: name, initialBalance: initialBalance);
  }

  @override
  Future<AppAccount> getAccountById(String id) => _service.getAccountById(id);

  @override
  Future<AppAccount> updateAccount({
    required String id,
    String? name,
    String? status,
  }) {
    return _service.updateAccount(id: id, name: name, status: status);
  }

  @override
  Future<void> addAdjustment({
    required String id,
    required double amount,
    required String reason,
  }) {
    return _service.addAdjustment(id: id, amount: amount, reason: reason);
  }
}
