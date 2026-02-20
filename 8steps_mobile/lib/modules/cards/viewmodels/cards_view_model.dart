import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_card.dart';
import '../repositories/cards_repository.dart';

class CardsState {
  const CardsState({
    this.loading = false,
    this.saving = false,
    this.cards = const [],
    this.selectedCard,
    this.charges = const [],
    this.installmentPlans = const [],
    this.payments = const [],
    this.errorMessage,
  });

  final bool loading;
  final bool saving;
  final List<AppCard> cards;
  final AppCard? selectedCard;
  final List<CardCharge> charges;
  final List<InstallmentPlan> installmentPlans;
  final List<CardPayment> payments;
  final String? errorMessage;

  CardsState copyWith({
    bool? loading,
    bool? saving,
    List<AppCard>? cards,
    AppCard? selectedCard,
    bool clearSelected = false,
    List<CardCharge>? charges,
    List<InstallmentPlan>? installmentPlans,
    List<CardPayment>? payments,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CardsState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      cards: cards ?? this.cards,
      selectedCard: clearSelected ? null : (selectedCard ?? this.selectedCard),
      charges: charges ?? this.charges,
      installmentPlans: installmentPlans ?? this.installmentPlans,
      payments: payments ?? this.payments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CardsViewModel extends StateNotifier<CardsState> {
  CardsViewModel(this._repo) : super(const CardsState());

  final CardsRepository _repo;

  Future<void> loadCards() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final cards = await _repo.getCards();
      state = state.copyWith(loading: false, cards: cards);
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(
          loading: false, errorMessage: 'No se pudo cargar tarjetas');
    }
  }

  Future<bool> createCard({
    required String name,
    required int cutoffDay,
    required int paymentDay,
    required double totalLimit,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.createCard(
        name: name,
        cutoffDay: cutoffDay,
        paymentDay: paymentDay,
        totalLimit: totalLimit,
      );
      await loadCards();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
          saving: false, errorMessage: 'No se pudo crear tarjeta');
      return false;
    }
  }

  Future<bool> updateCard({
    required String id,
    String? name,
    int? cutoffDay,
    int? paymentDay,
    double? totalLimit,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.updateCard(
        id: id,
        name: name,
        cutoffDay: cutoffDay,
        paymentDay: paymentDay,
        totalLimit: totalLimit,
      );
      await loadCards();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
          saving: false, errorMessage: 'No se pudo actualizar tarjeta');
      return false;
    }
  }

  Future<bool> deleteCard(String id) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.deleteCard(id);
      await loadCards();
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
          saving: false, errorMessage: 'No se pudo eliminar tarjeta');
      return false;
    }
  }

  Future<void> loadCardDetail(
    String cardId, {
    DateTime? from,
    DateTime? to,
    String? month,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final now = DateTime.now();
      final rangeFrom = from ?? DateTime(now.year, now.month, 1);
      final rangeTo = to ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final result = await Future.wait<dynamic>([
        _repo.getCard(cardId),
        _repo.getCharges(cardId: cardId, from: rangeFrom, to: rangeTo, page: 1),
        _repo.getInstallmentPlans(cardId, month: month),
        _repo.getPayments(
            cardId: cardId, from: rangeFrom, to: rangeTo, page: 1),
      ]);
      state = state.copyWith(
        loading: false,
        selectedCard: result[0] as AppCard,
        charges: result[1] as List<CardCharge>,
        installmentPlans: result[2] as List<InstallmentPlan>,
        payments: result[3] as List<CardPayment>,
      );
    } on DioException catch (e) {
      state = state.copyWith(loading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(
          loading: false, errorMessage: 'No se pudo cargar detalle');
    }
  }

  Future<bool> createCharge({
    required String cardId,
    required String name,
    required double amount,
    required DateTime occurredAt,
    required String type,
    int? installmentsCount,
    int? progressInstallments,
    String? startMonth,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.createCharge(
        cardId: cardId,
        name: name,
        amount: amount,
        occurredAt: occurredAt,
        type: type,
        installmentsCount: installmentsCount,
        progressInstallments: progressInstallments,
        startMonth: startMonth,
      );
      await loadCardDetail(cardId);
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
          saving: false, errorMessage: 'No se pudo registrar cargo');
      return false;
    }
  }

  Future<bool> updateCharge({
    required String cardId,
    required String chargeId,
    required String type,
    String? name,
    double? amount,
    DateTime? occurredAt,
    int? installmentsCount,
    int? progressInstallments,
    String? startMonth,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.updateCharge(
        cardId: cardId,
        chargeId: chargeId,
        type: type,
        name: name,
        amount: amount,
        occurredAt: occurredAt,
        installmentsCount: installmentsCount,
        progressInstallments: progressInstallments,
        startMonth: startMonth,
      );
      await loadCardDetail(cardId);
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 405 &&
          name != null &&
          amount != null &&
          occurredAt != null) {
        try {
          // Fallback when backend does not support PATCH /charges/{id}:
          // recreate with new values and delete previous charge.
          await _repo.createCharge(
            cardId: cardId,
            name: name,
            amount: amount,
            occurredAt: occurredAt,
            type: type,
            installmentsCount: installmentsCount,
            progressInstallments: progressInstallments,
            startMonth: startMonth,
          );
          await _repo.deleteCharge(cardId: cardId, chargeId: chargeId);
          await loadCardDetail(cardId);
          state = state.copyWith(saving: false);
          return true;
        } on DioException catch (fallbackError) {
          state = state.copyWith(
            saving: false,
            errorMessage: _mapError(fallbackError),
          );
          return false;
        } catch (_) {
          state = state.copyWith(
            saving: false,
            errorMessage: 'No se pudo editar cargo',
          );
          return false;
        }
      }
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
          saving: false, errorMessage: 'No se pudo editar cargo');
      return false;
    }
  }

  Future<bool> deleteCharge({
    required String cardId,
    required String chargeId,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.deleteCharge(cardId: cardId, chargeId: chargeId);
      await loadCardDetail(cardId);
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'No se pudo eliminar cargo',
      );
      return false;
    }
  }

  Future<bool> createInstallmentPlan({
    required String cardId,
    required String label,
    required double monthlyAmount,
    required int totalInstallments,
    required String startMonth,
    required int progressInstallments,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.createInstallmentPlan(
        cardId: cardId,
        label: label,
        monthlyAmount: monthlyAmount,
        totalInstallments: totalInstallments,
        startMonth: startMonth,
        progressInstallments: progressInstallments,
      );
      await loadCardDetail(cardId);
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state =
          state.copyWith(saving: false, errorMessage: 'No se pudo crear plan');
      return false;
    }
  }

  Future<bool> createPayment({
    required String cardId,
    required double amount,
    required DateTime paidAt,
    String? fromAccountId,
    String? note,
  }) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      await _repo.createPayment(
        cardId: cardId,
        amount: amount,
        paidAt: paidAt,
        fromAccountId: fromAccountId,
        note: note,
      );
      await loadCardDetail(cardId);
      state = state.copyWith(saving: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(saving: false, errorMessage: _mapError(e));
      return false;
    } catch (_) {
      state = state.copyWith(
          saving: false, errorMessage: 'No se pudo registrar pago');
      return false;
    }
  }

  Future<String?> payCard({
    required String cardId,
    required double amount,
    required DateTime paidAt,
    String? fromAccountId,
    String? note,
  }) async {
    final result = await submitPayment(
      cardId: cardId,
      amount: amount,
      date: paidAt,
      fromAccountId: fromAccountId,
      note: note,
    );
    if (result.success) return null;
    return result.message ?? 'No se pudo registrar pago';
  }

  Future<CardPaymentContext?> getPaymentContext({
    required String cardId,
    DateTime? asOf,
  }) async {
    try {
      return await _repo.getPaymentContext(
        cardId: cardId,
        asOf: asOf ?? DateTime.now(),
      );
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: _mapError(e));
      return null;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'No se pudo cargar contexto de pago',
      );
      return null;
    }
  }

  Future<CardPaymentSubmissionResult> submitPayment({
    required String cardId,
    required DateTime date,
    required double amount,
    String? fromAccountId,
    List<PaymentAllocationInput>? allocations,
    String? note,
  }) async {
    final result = await _repo.submitPayment(
      cardId: cardId,
      date: date,
      amount: amount,
      fromAccountId: fromAccountId,
      allocations: allocations,
      note: note,
    );

    if (result.success) {
      await loadCardDetail(cardId);
    }
    return result;
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
    if (status == 405) {
      return 'El backend no permite editar este cargo (HTTP 405)';
    }
    if (status != null) return 'Error del servidor (HTTP $status)';
    return 'Ocurrió un error';
  }
}
