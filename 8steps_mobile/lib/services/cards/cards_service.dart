import 'package:dio/dio.dart';

import '../../modules/cards/models/app_card.dart';

class CardsService {
  CardsService(this._dio);

  final Dio _dio;

  Future<List<AppCard>> getCards() async {
    final response = await _dio.get('/cards');
    final body = response.data;
    final raw = switch (body) {
      List<dynamic> l => l,
      Map<String, dynamic> m => (m['cards'] as List<dynamic>?) ?? const [],
      _ => const [],
    };

    return raw.whereType<Map<String, dynamic>>().map(AppCard.fromJson).toList();
  }

  Future<AppCard> createCard({
    required String name,
    required int cutoffDay,
    required int paymentDay,
    required double totalLimit,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/cards',
      data: {
        'name': name,
        'cutoffDay': cutoffDay,
        'paymentDay': paymentDay,
        'totalLimit': totalLimit,
      },
    );

    final json = _extractCard(response.data);
    if (json == null) {
      throw const FormatException('Respuesta inválida al crear tarjeta');
    }
    return AppCard.fromJson(json);
  }

  Future<AppCard> getCard(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/cards/$id');
    final json = _extractCard(response.data);
    if (json == null) {
      throw const FormatException('Respuesta inválida del detalle de tarjeta');
    }
    return AppCard.fromJson(json);
  }

  Future<AppCard> updateCard({
    required String id,
    String? name,
    int? cutoffDay,
    int? paymentDay,
    double? totalLimit,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/cards/$id',
      data: {
        if (name != null) 'name': name,
        if (cutoffDay != null) 'cutoffDay': cutoffDay,
        if (paymentDay != null) 'paymentDay': paymentDay,
        if (totalLimit != null) 'totalLimit': totalLimit,
      },
    );

    final json = _extractCard(response.data);
    if (json == null) {
      throw const FormatException('Respuesta inválida al actualizar tarjeta');
    }
    return AppCard.fromJson(json);
  }

  Future<void> deleteCard(String id) async {
    await _dio.delete('/cards/$id');
  }

  Future<List<CardCharge>> getCharges({
    required String cardId,
    required DateTime from,
    required DateTime to,
    int page = 1,
  }) async {
    final response = await _dio.get(
      '/cards/$cardId/charges',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'page': page,
      },
    );

    final body = response.data;
    final raw = switch (body) {
      List<dynamic> l => l,
      Map<String, dynamic> m => (m['charges'] as List<dynamic>?) ?? const [],
      _ => const [],
    };

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CardCharge.fromJson)
        .toList();
  }

  Future<void> createCharge({
    required String cardId,
    required String name,
    required double amount,
    required DateTime occurredAt,
    required String type,
    int? installmentsCount,
    int? progressInstallments,
    String? startMonth,
  }) async {
    await _dio.post(
      '/cards/$cardId/charges',
      data: {
        'name': name,
        'amount': amount,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'type': type,
        if (type == 'deferred' && installmentsCount != null)
          'installmentsCount': installmentsCount,
        if (type == 'deferred' && progressInstallments != null)
          'progressInstallments': progressInstallments,
        if (type == 'deferred' && startMonth != null) 'startMonth': startMonth,
      },
    );
  }

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
  }) async {
    await _dio.patch(
      '/cards/$cardId/charges/$chargeId',
      data: {
        'type': type,
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount,
        if (occurredAt != null)
          'occurredAt': occurredAt.toUtc().toIso8601String(),
        if (installmentsCount != null) 'installmentsCount': installmentsCount,
        if (progressInstallments != null)
          'progressInstallments': progressInstallments,
        if (startMonth != null) 'startMonth': startMonth,
      },
    );
  }

  Future<void> deleteCharge({
    required String cardId,
    required String chargeId,
  }) async {
    await _dio.delete('/cards/$cardId/charges/$chargeId');
  }

  Future<List<InstallmentPlan>> getInstallmentPlans(
    String cardId, {
    String? month,
  }) async {
    final response = await _dio.get(
      '/cards/$cardId/installment-plans',
      queryParameters: {
        if (month != null && month.isNotEmpty) 'month': month,
      },
    );
    final body = response.data;
    final raw = switch (body) {
      List<dynamic> l => l,
      Map<String, dynamic> m => (m['installmentPlans'] as List<dynamic>?) ??
          (m['plans'] as List<dynamic>?) ??
          const [],
      _ => const [],
    };
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InstallmentPlan.fromJson)
        .toList();
  }

  Future<void> createInstallmentPlan({
    required String cardId,
    required String label,
    required double monthlyAmount,
    required int totalInstallments,
    required String startMonth,
    required int progressInstallments,
  }) async {
    await _dio.post(
      '/cards/$cardId/installment-plans',
      data: {
        'label': label,
        'monthlyAmount': monthlyAmount,
        'totalInstallments': totalInstallments,
        'startMonth': startMonth,
        'progressInstallments': progressInstallments,
      },
    );
  }

  Future<InstallmentPlan> getInstallmentPlan(String planId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/installment-plans/$planId');
    final body = response.data;
    final json = body?['installmentPlan'] is Map<String, dynamic>
        ? body!['installmentPlan'] as Map<String, dynamic>
        : body;
    if (json == null) throw const FormatException('Respuesta inválida de plan');
    return InstallmentPlan.fromJson(json);
  }

  Future<List<CardPayment>> getPayments({
    required String cardId,
    required DateTime from,
    required DateTime to,
    int page = 1,
  }) async {
    final response = await _dio.get(
      '/cards/$cardId/payments',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'page': page,
      },
    );

    final body = response.data;
    final raw = switch (body) {
      List<dynamic> l => l,
      Map<String, dynamic> m => (m['payments'] as List<dynamic>?) ?? const [],
      _ => const [],
    };

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CardPayment.fromJson)
        .toList();
  }

  Future<void> createPayment({
    required String cardId,
    required double amount,
    required DateTime paidAt,
    String? fromAccountId,
    String? note,
  }) async {
    await _dio.post(
      '/cards/$cardId/payments',
      data: {
        'amount': amount,
        if (fromAccountId != null) 'fromAccountId': fromAccountId,
        'paidAt': paidAt.toUtc().toIso8601String(),
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  Future<CardPaymentContext> getPaymentContext({
    required String cardId,
    required DateTime asOf,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/cards/$cardId/payment-context',
      queryParameters: {
        'as_of':
            '${asOf.year}-${asOf.month.toString().padLeft(2, '0')}-${asOf.day.toString().padLeft(2, '0')}',
      },
    );
    final body = response.data;
    if (body == null) {
      throw const FormatException('Respuesta inválida de payment-context');
    }
    return CardPaymentContext.fromJson(body);
  }

  Future<CardPaymentSubmissionResult> submitPayment({
    required String cardId,
    required DateTime date,
    required double amount,
    String? fromAccountId,
    List<PaymentAllocationInput>? allocations,
    String? note,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/cards/$cardId/payments',
        data: {
          'date': date.toUtc().toIso8601String(),
          'amount': amount,
          if (fromAccountId != null) 'from_account_id': fromAccountId,
          if (allocations != null && allocations.isNotEmpty)
            'allocations': allocations.map((e) => e.toJson()).toList(),
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final body = response.data;
      final message =
          body is Map<String, dynamic> ? body['message']?.toString() : null;
      return CardPaymentSubmissionResult.success(message: message);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final requiresAllocation = data['requires_allocation'] == true;
        final message =
            data['message']?.toString() ?? 'No se pudo registrar pago';
        final contextJson = data['payment_context'];
        final paymentContext = contextJson is Map<String, dynamic>
            ? CardPaymentContext.fromJson(contextJson)
            : null;
        return CardPaymentSubmissionResult.failure(
          message: message,
          requiresAllocation: requiresAllocation,
          paymentContext: paymentContext,
        );
      }
      return CardPaymentSubmissionResult.failure(
        message: 'No se pudo registrar pago',
      );
    }
  }

  Map<String, dynamic>? _extractCard(Map<String, dynamic>? body) {
    if (body == null) return null;
    final candidate = body['card'];
    if (candidate is Map<String, dynamic>) return candidate;
    if (body.containsKey('id') && body.containsKey('name')) return body;
    return null;
  }
}
