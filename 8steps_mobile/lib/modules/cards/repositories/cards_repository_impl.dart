import '../../../services/cards/cards_service.dart';
import '../models/app_card.dart';
import 'cards_repository.dart';

class CardsRepositoryImpl implements CardsRepository {
  CardsRepositoryImpl(this._service);

  final CardsService _service;

  @override
  Future<List<AppCard>> getCards() => _service.getCards();

  @override
  Future<AppCard> createCard({
    required String name,
    required int cutoffDay,
    required int paymentDay,
    required double totalLimit,
  }) {
    return _service.createCard(
      name: name,
      cutoffDay: cutoffDay,
      paymentDay: paymentDay,
      totalLimit: totalLimit,
    );
  }

  @override
  Future<AppCard> getCard(String id) => _service.getCard(id);

  @override
  Future<AppCard> updateCard({
    required String id,
    String? name,
    int? cutoffDay,
    int? paymentDay,
    double? totalLimit,
  }) {
    return _service.updateCard(
      id: id,
      name: name,
      cutoffDay: cutoffDay,
      paymentDay: paymentDay,
      totalLimit: totalLimit,
    );
  }

  @override
  Future<void> deleteCard(String id) => _service.deleteCard(id);

  @override
  Future<List<CardCharge>> getCharges({
    required String cardId,
    required DateTime from,
    required DateTime to,
    int page = 1,
  }) {
    return _service.getCharges(cardId: cardId, from: from, to: to, page: page);
  }

  @override
  Future<void> createCharge({
    required String cardId,
    required String name,
    required double amount,
    required DateTime occurredAt,
    required String type,
    int? installmentsCount,
    int? progressInstallments,
    String? startMonth,
  }) {
    return _service.createCharge(
      cardId: cardId,
      name: name,
      amount: amount,
      occurredAt: occurredAt,
      type: type,
      installmentsCount: installmentsCount,
      progressInstallments: progressInstallments,
      startMonth: startMonth,
    );
  }

  @override
  Future<void> updateCharge({
    required String cardId,
    required String chargeId,
    required String type,
    String? name,
    double? amount,
    DateTime? occurredAt,
    int? installmentsCount,
    int? progressInstallments,
    String? startMonth,
  }) {
    return _service.updateCharge(
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
  }

  @override
  Future<void> deleteCharge({
    required String cardId,
    required String chargeId,
  }) {
    return _service.deleteCharge(cardId: cardId, chargeId: chargeId);
  }

  @override
  Future<List<InstallmentPlan>> getInstallmentPlans(
    String cardId, {
    String? month,
  }) {
    return _service.getInstallmentPlans(cardId, month: month);
  }

  @override
  Future<void> createInstallmentPlan({
    required String cardId,
    required String label,
    required double monthlyAmount,
    required int totalInstallments,
    required String startMonth,
    required int progressInstallments,
  }) {
    return _service.createInstallmentPlan(
      cardId: cardId,
      label: label,
      monthlyAmount: monthlyAmount,
      totalInstallments: totalInstallments,
      startMonth: startMonth,
      progressInstallments: progressInstallments,
    );
  }

  @override
  Future<InstallmentPlan> getInstallmentPlan(String planId) {
    return _service.getInstallmentPlan(planId);
  }

  @override
  Future<List<CardPayment>> getPayments({
    required String cardId,
    required DateTime from,
    required DateTime to,
    int page = 1,
  }) {
    return _service.getPayments(cardId: cardId, from: from, to: to, page: page);
  }

  @override
  Future<void> createPayment({
    required String cardId,
    required double amount,
    required DateTime paidAt,
    String? fromAccountId,
    String? note,
  }) {
    return _service.createPayment(
      cardId: cardId,
      amount: amount,
      paidAt: paidAt,
      fromAccountId: fromAccountId,
      note: note,
    );
  }

  @override
  Future<CardPaymentContext> getPaymentContext({
    required String cardId,
    required DateTime asOf,
  }) {
    return _service.getPaymentContext(cardId: cardId, asOf: asOf);
  }

  @override
  Future<CardPaymentSubmissionResult> submitPayment({
    required String cardId,
    required DateTime date,
    required double amount,
    String? fromAccountId,
    List<PaymentAllocationInput>? allocations,
    String? note,
  }) {
    return _service.submitPayment(
      cardId: cardId,
      date: date,
      amount: amount,
      fromAccountId: fromAccountId,
      allocations: allocations,
      note: note,
    );
  }
}
