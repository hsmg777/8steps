import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report_models.dart';
import '../repositories/reports_repository.dart';

enum ReportPeriod { monthly, yearly }

class ReportsState {
  const ReportsState({
    this.loading = false,
    this.period = ReportPeriod.monthly,
    this.selectedMonth,
    this.selectedYear,
    this.monthly,
    this.yearly,
    this.errorMessage,
  });

  final bool loading;
  final ReportPeriod period;
  final String? selectedMonth;
  final int? selectedYear;
  final MonthlyReport? monthly;
  final YearlyReport? yearly;
  final String? errorMessage;

  ReportsState copyWith({
    bool? loading,
    ReportPeriod? period,
    String? selectedMonth,
    int? selectedYear,
    MonthlyReport? monthly,
    YearlyReport? yearly,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportsState(
      loading: loading ?? this.loading,
      period: period ?? this.period,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      monthly: monthly ?? this.monthly,
      yearly: yearly ?? this.yearly,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReportsViewModel extends StateNotifier<ReportsState> {
  ReportsViewModel(this._repo)
      : super(
          ReportsState(
            selectedMonth: _formatMonth(DateTime.now()),
            selectedYear: DateTime.now().year,
          ),
        );

  final ReportsRepository _repo;

  Future<void> loadInitial() async {
    await loadMonthly(
        month: state.selectedMonth ?? _formatMonth(DateTime.now()));
  }

  Future<void> setPeriod(ReportPeriod period) async {
    if (period == state.period) return;
    state = state.copyWith(period: period, clearError: true);
    if (period == ReportPeriod.monthly) {
      await loadMonthly(
          month: state.selectedMonth ?? _formatMonth(DateTime.now()));
    } else {
      await loadYearly(year: state.selectedYear ?? DateTime.now().year);
    }
  }

  Future<void> loadMonthly({required String month}) async {
    state = state.copyWith(
      loading: true,
      period: ReportPeriod.monthly,
      selectedMonth: month,
      clearError: true,
    );
    try {
      final monthly = await _repo.getMonthlyReport(month: month);
      state = state.copyWith(loading: false, monthly: monthly);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'No se pudo cargar reporte mensual',
      );
    }
  }

  Future<void> loadYearly({required int year}) async {
    state = state.copyWith(
      loading: true,
      period: ReportPeriod.yearly,
      selectedYear: year,
      clearError: true,
    );
    try {
      final yearly = await _repo.getYearlyReport(year: year);
      state = state.copyWith(loading: false, yearly: yearly);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'No se pudo cargar reporte anual',
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

  static String _formatMonth(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}-$m';
  }
}
