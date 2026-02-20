import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_balance.dart';
import '../repositories/dashboard_repository.dart';

class DashboardState {
  const DashboardState({
    this.loading = false,
    this.balance = DashboardBalance.empty,
    this.errorMessage,
  });

  final bool loading;
  final DashboardBalance balance;
  final String? errorMessage;

  DashboardState copyWith({
    bool? loading,
    DashboardBalance? balance,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      balance: balance ?? this.balance,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DashboardViewModel extends StateNotifier<DashboardState> {
  DashboardViewModel(this._repo) : super(const DashboardState());

  final DashboardRepository _repo;

  Future<void> loadBalance() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final balance = await _repo.getBalance();
      state = state.copyWith(loading: false, balance: balance);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'No se pudo cargar balance',
      );
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
