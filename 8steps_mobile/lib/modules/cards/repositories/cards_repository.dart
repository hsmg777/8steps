import '../models/app_card.dart';

abstract class CardsRepository {
  Future<List<AppCard>> getCards();
  Future<AppCard> createCard({
    required String name,
    required int cutoffDay,
    required int paymentDay,
    required double totalLimit,
  });
  Future<AppCard> getCard(String id);
  Future<AppCard> updateCard({
    required String id,
    String? name,
    int? cutoffDay,
    int? paymentDay,
    double? totalLimit,
  });
  Future<void> deleteCard(String id);

  Future<List<CardCharge>> getCharges({
    required String cardId,
    required DateTime from,
    required DateTime to,
    int page = 1,
  });
  Future<void> createCharge({
    required String cardId,
    required String name,
    required double amount,
    required DateTime occurredAt,
    required String type,
    int? installmentsCount,
    int? progressInstallments,
    String? startMonth,
  });
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
  });
  Future<void> deleteCharge({
    required String cardId,
    required String chargeId,
  });

  Future<List<InstallmentPlan>> getInstallmentPlans(
    String cardId, {
    String? month,
  });
  Future<void> createInstallmentPlan({
    required String cardId,
    required String label,
    required double monthlyAmount,
    required int totalInstallments,
    required String startMonth,
    required int progressInstallments,
  });
  Future<InstallmentPlan> getInstallmentPlan(String planId);

  Future<List<CardPayment>> getPayments({
    required String cardId,
    required DateTime from,
    required DateTime to,
    int page = 1,
  });
  Future<void> createPayment({
    required String cardId,
    required double amount,
    required DateTime paidAt,
    String? fromAccountId,
    String? note,
  });

  Future<CardPaymentContext> getPaymentContext({
    required String cardId,
    required DateTime asOf,
  });

  Future<CardPaymentSubmissionResult> submitPayment({
    required String cardId,
    required DateTime date,
    required double amount,
    String? fromAccountId,
    List<PaymentAllocationInput>? allocations,
    String? note,
  });
}
