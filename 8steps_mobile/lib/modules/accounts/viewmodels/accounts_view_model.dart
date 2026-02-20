import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_account.dart';
import '../repositories/accounts_repository.dart';

class AccountsState {
  const AccountsState({
    this.loading = false,
    this.saving = false,
    this.accounts = const [],
    this.errorMessage,
  });

  final bool loading;
  final bool saving;
  final List<AppAccount> accounts;
  final String? errorMessage;

  AccountsState copyWith({
    bool? loading,
    bool? saving,
    List<AppAccount>? accounts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountsState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      accounts: accounts ?? this.accounts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AccountsViewModel extends StateNotifier<AccountsState> {
  AccountsViewModel(this._repo) : super(const AccountsState());

  final AccountsRepository _repo;

  Future<void> loadAccounts() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final items = await _repo.getAccounts();
      state = state.copyWith(loading: false, accounts: items);
    } on DioException catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: _mapError(e),
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'No se pudo cargar cuentas',
      );
    }
  }

  Future<bool> createAccount({
    required String name,
    required double initialBalance,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.createAccount(name: name, initialBalance: initialBalance);
      await loadAccounts();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'No se pudo crear la cuenta',
      );
      return false;
    }
  }

  Future<AppAccount?> getAccountById(String id) async {
    try {
      return await _repo.getAccountById(id);
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: _mapError(e));
      return null;
    } catch (_) {
      state = state.copyWith(errorMessage: 'No se pudo cargar el detalle');
      return null;
    }
  }

  Future<bool> updateAccount({
    required String id,
    String? name,
    String? status,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.updateAccount(id: id, name: name, status: status);
      await loadAccounts();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'No se pudo actualizar la cuenta',
      );
      return false;
    }
  }

  Future<bool> addAdjustment({
    required String id,
    required double amount,
    required String reason,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.addAdjustment(id: id, amount: amount, reason: reason);
      await loadAccounts();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'No se pudo aplicar el ajuste',
      );
      return false;
    }
  }

  String _mapError(DioException e) {
    final data = e.response?.data;
    final apiMessage = data is Map<String, dynamic>
        ? data['message'] as String?
        : (data is String ? data : null);
    if (apiMessage != null && apiMessage.isNotEmpty) {
      if (apiMessage.contains('<!DOCTYPE html') ||
          apiMessage.contains('<html')) {
        return 'La API devolvió HTML. Revisa la ruta /api/v1.';
      }
      return apiMessage;
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'No se pudo conectar';
    }

    final status = e.response?.statusCode;
    if (status != null) {
      return 'Error del servidor (HTTP $status)';
    }

    return 'Ocurrió un error';
  }
}
