import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_event.dart';
import '../repositories/calendar_repository.dart';

class CalendarState {
  const CalendarState({
    this.loading = false,
    this.events = const [],
    this.detailLoading = false,
    this.selectedDetail,
    this.errorMessage,
  });

  final bool loading;
  final List<CalendarEvent> events;
  final bool detailLoading;
  final CalendarEventDetail? selectedDetail;
  final String? errorMessage;

  CalendarState copyWith({
    bool? loading,
    List<CalendarEvent>? events,
    bool? detailLoading,
    CalendarEventDetail? selectedDetail,
    String? errorMessage,
    bool clearError = false,
    bool clearDetail = false,
  }) {
    return CalendarState(
      loading: loading ?? this.loading,
      events: events ?? this.events,
      detailLoading: detailLoading ?? this.detailLoading,
      selectedDetail:
          clearDetail ? null : (selectedDetail ?? this.selectedDetail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CalendarViewModel extends StateNotifier<CalendarState> {
  CalendarViewModel(this._repo) : super(const CalendarState());

  final CalendarRepository _repo;

  Future<void> loadEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final events = await _repo.getEvents(from: from, to: to);
      state = state.copyWith(loading: false, events: events);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'No se pudo cargar calendario',
      );
    }
  }

  Future<CalendarEventDetail?> loadEventDetail(String id) async {
    state = state.copyWith(detailLoading: true, clearError: true);
    try {
      final detail = await _repo.getEventDetail(id);
      state = state.copyWith(detailLoading: false, selectedDetail: detail);
      return detail;
    } on DioException catch (e) {
      state = state.copyWith(detailLoading: false, errorMessage: _mapError(e));
      return null;
    } catch (_) {
      state = state.copyWith(
        detailLoading: false,
        errorMessage: 'No se pudo cargar detalle del evento',
      );
      return null;
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
