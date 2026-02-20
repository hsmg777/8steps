import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_transaction.dart';
import '../repositories/transactions_repository.dart';

class TransactionsState {
  const TransactionsState({
    this.loading = false,
    this.saving = false,
    this.items = const [],
    this.errorMessage,
    this.page = 1,
    this.totalPages = 1,
    this.from,
    this.to,
    this.type,
    this.accountId,
    this.categoryId,
  });

  final bool loading;
  final bool saving;
  final List<AppTransaction> items;
  final String? errorMessage;

  final int page;
  final int totalPages;
  final DateTime? from;
  final DateTime? to;
  final String? type;
  final String? accountId;
  final String? categoryId;

  bool get hasPrev => page > 1;
  bool get hasNext => page < totalPages;

  TransactionsState copyWith({
    bool? loading,
    bool? saving,
    List<AppTransaction>? items,
    String? errorMessage,
    bool clearError = false,
    int? page,
    int? totalPages,
    DateTime? from,
    DateTime? to,
    String? type,
    bool clearType = false,
    String? accountId,
    bool clearAccount = false,
    String? categoryId,
    bool clearCategory = false,
  }) {
    return TransactionsState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      from: from ?? this.from,
      to: to ?? this.to,
      type: clearType ? null : (type ?? this.type),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

class TransactionsViewModel extends StateNotifier<TransactionsState> {
  TransactionsViewModel(this._repo)
      : super(
          TransactionsState(
            from: DateTime(DateTime.now().year, DateTime.now().month, 1),
            to: DateTime(
                DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59),
          ),
        );

  final TransactionsRepository _repo;

  Future<void> load({int? page}) async {
    final from = state.from;
    final to = state.to;
    if (from == null || to == null) return;

    final nextPage = page ?? state.page;
    state = state.copyWith(loading: true, clearError: true, page: nextPage);

    try {
      final result = await _repo.getTransactions(
        from: from,
        to: to,
        type: state.type,
        accountId: state.accountId,
        categoryId: state.categoryId,
        page: nextPage,
      );
      state = state.copyWith(
        loading: false,
        items: result.items,
        page: result.page,
        totalPages: result.totalPages,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(
          loading: false, errorMessage: 'No se pudo cargar movimientos');
    }
  }

  void setDateRange({required DateTime from, required DateTime to}) {
    state = state.copyWith(from: from, to: to, page: 1);
  }

  void setType(String? type) {
    state = state.copyWith(type: type, clearType: type == null, page: 1);
  }

  void setAccount(String? accountId) {
    state = state.copyWith(
        accountId: accountId, clearAccount: accountId == null, page: 1);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(
        categoryId: categoryId, clearCategory: categoryId == null, page: 1);
  }

  void clearFilters() {
    final now = DateTime.now();
    state = state.copyWith(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      clearType: true,
      clearAccount: true,
      clearCategory: true,
      page: 1,
    );
  }

  Future<bool> createTransaction({
    required String type,
    required double amount,
    String? categoryId,
    required DateTime occurredAt,
    String? accountId,
    String? note,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.createTransaction(
        type: type,
        amount: amount,
        categoryId: categoryId,
        occurredAt: occurredAt,
        accountId: accountId,
        note: note,
      );
      await load(page: 1);
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } on FormatException catch (e) {
      state = state.copyWith(saving: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(saving: false, errorMessage: 'No se pudo crear');
      return false;
    }
  }

  Future<AppTransaction?> getById(String id) async {
    try {
      return await _repo.getTransactionById(id);
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: _mapError(e));
      return null;
    } catch (_) {
      state = state.copyWith(errorMessage: 'No se pudo cargar detalle');
      return null;
    }
  }

  Future<bool> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? accountId,
    String? categoryId,
    DateTime? occurredAt,
    String? note,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.updateTransaction(
        id: id,
        type: type,
        amount: amount,
        accountId: accountId,
        categoryId: categoryId,
        occurredAt: occurredAt,
        note: note,
      );
      await load(page: state.page);
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } on FormatException catch (e) {
      state = state.copyWith(saving: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state =
          state.copyWith(saving: false, errorMessage: 'No se pudo actualizar');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.deleteTransaction(id);
      await load(page: state.page);
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state =
          state.copyWith(saving: false, errorMessage: 'No se pudo eliminar');
      return false;
    }
  }

  String _mapError(DioException e) {
    final data = e.response?.data;
    final msg = data is Map<String, dynamic>
        ? data['message'] as String?
        : (data is String ? data : null);
    if (msg != null && msg.isNotEmpty) return msg;

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'No se pudo conectar';
    }

    final status = e.response?.statusCode;
    if (status != null) return 'Error del servidor (HTTP $status)';
    return 'Ocurrió un error';
  }
}
