class AppCard {
  const AppCard({
    required this.id,
    required this.name,
    required this.cutoffDay,
    required this.paymentDay,
    required this.totalLimit,
    required this.currentDebt,
    required this.availableLimit,
    required this.utilizationPercent,
    required this.nextPaymentAmount,
    this.nextPaymentDate,
    required this.paymentStatus,
  });

  final String id;
  final String name;
  final int cutoffDay;
  final int paymentDay;
  final double totalLimit;
  final double currentDebt;
  final double availableLimit;
  final double utilizationPercent;
  final double nextPaymentAmount;
  final DateTime? nextPaymentDate;
  final String paymentStatus;

  double get totalDebt => currentDebt;
  double get available => availableLimit;

  factory AppCard.fromJson(Map<String, dynamic> json) {
    final statement = json['statementPreview'] is Map<String, dynamic>
        ? json['statementPreview'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final totalLimit = _toDouble(json['totalLimit'] ?? json['total_limit']);
    final currentDebt = _toDouble(
      json['currentDebt'] ??
          json['current_debt'] ??
          json['totalDebt'] ??
          json['total_debt'] ??
          json['debt'],
    );
    final availableLimit = (json.containsKey('availableLimit') ||
            json.containsKey('available_limit'))
        ? _toDouble(json['availableLimit'] ?? json['available_limit'])
        : (json.containsKey('available') || json.containsKey('available_amount')
            ? _toDouble(json['available'] ?? json['available_amount'])
            : (totalLimit - currentDebt));

    return AppCard(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Tarjeta').toString(),
      cutoffDay: _toInt(json['cutoffDay'] ?? json['cutoff_day'], 1),
      paymentDay: _toInt(json['paymentDay'] ?? json['payment_day'], 1),
      totalLimit: totalLimit,
      currentDebt: currentDebt,
      availableLimit: availableLimit,
      utilizationPercent: _toDouble(json['utilizationPercent']),
      nextPaymentAmount: _toDouble(statement['nextPaymentAmount']),
      nextPaymentDate:
          DateTime.tryParse((statement['nextPaymentDate'] ?? '').toString()),
      paymentStatus:
          (statement['paymentStatus'] ?? json['paymentStatus'] ?? 'PENDING')
              .toString(),
    );
  }
}

class CardCharge {
  const CardCharge({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.occurredAt,
    this.installmentsCount,
    this.progressInstallments,
    this.startMonth,
  });

  final String id;
  final String name;
  final double amount;
  final String type;
  final DateTime occurredAt;
  final int? installmentsCount;
  final int? progressInstallments;
  final String? startMonth;

  bool get isDeferred => type == 'deferred';

  factory CardCharge.fromJson(Map<String, dynamic> json) {
    return CardCharge(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Cargo').toString(),
      amount: _toDouble(json['amount']),
      type: (json['type'] ?? 'current').toString(),
      occurredAt: DateTime.tryParse((json['occurredAt'] ?? '').toString()) ??
          DateTime.now(),
      installmentsCount: json['installmentsCount'] == null
          ? null
          : _toInt(json['installmentsCount'], 0),
      progressInstallments: json['progressInstallments'] == null
          ? null
          : _toInt(json['progressInstallments'], 0),
      startMonth: json['startMonth']?.toString(),
    );
  }
}

class InstallmentPlan {
  const InstallmentPlan({
    required this.id,
    required this.label,
    required this.monthlyAmount,
    required this.totalInstallments,
    required this.progressInstallments,
    required this.startMonth,
    this.progressLabel,
    this.monthInstallment,
  });

  final String id;
  final String label;
  final double monthlyAmount;
  final int totalInstallments;
  final int progressInstallments;
  final String startMonth;
  final String? progressLabel;
  final MonthInstallment? monthInstallment;

  factory InstallmentPlan.fromJson(Map<String, dynamic> json) {
    final monthInstallmentJson = json['monthInstallment'];
    return InstallmentPlan(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? 'Plan').toString(),
      monthlyAmount:
          _toDouble(json['monthlyAmount'] ?? monthInstallmentJson?['amount']),
      totalInstallments: _toInt(json['totalInstallments'], 0),
      progressInstallments: _toInt(json['progressInstallments'], 0),
      startMonth: (json['startMonth'] ?? monthInstallmentJson?['month'] ?? '')
          .toString(),
      progressLabel: json['progressLabel']?.toString(),
      monthInstallment: monthInstallmentJson is Map<String, dynamic>
          ? MonthInstallment.fromJson(monthInstallmentJson)
          : null,
    );
  }
}

class MonthInstallment {
  const MonthInstallment({
    required this.month,
    required this.installmentNumber,
    required this.amount,
    required this.paidAmount,
    required this.status,
  });

  final String month;
  final int installmentNumber;
  final double amount;
  final double paidAmount;
  final String status;

  factory MonthInstallment.fromJson(Map<String, dynamic> json) {
    return MonthInstallment(
      month: (json['month'] ?? '').toString(),
      installmentNumber: _toInt(json['installmentNumber'], 0),
      amount: _toDouble(json['amount']),
      paidAmount: _toDouble(json['paidAmount']),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class CardPayment {
  const CardPayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.note,
  });

  final String id;
  final double amount;
  final DateTime paidAt;
  final String? note;

  factory CardPayment.fromJson(Map<String, dynamic> json) {
    return CardPayment(
      id: (json['id'] ?? '').toString(),
      amount: _toDouble(json['amount']),
      paidAt: DateTime.tryParse((json['paidAt'] ?? '').toString()) ??
          DateTime.now(),
      note: json['note']?.toString(),
    );
  }
}

class CardPaymentContext {
  const CardPaymentContext({
    required this.asOf,
    required this.dueThisPeriod,
    required this.paidThisPeriod,
    required this.remainingDue,
    required this.totalDebt,
    required this.allocatableTargets,
  });

  final String asOf;
  final double dueThisPeriod;
  final double paidThisPeriod;
  final double remainingDue;
  final double totalDebt;
  final List<PaymentAllocationTarget> allocatableTargets;

  factory CardPaymentContext.fromJson(Map<String, dynamic> json) {
    final rawTargets =
        (json['allocatable_targets'] as List<dynamic>?) ?? const [];
    return CardPaymentContext(
      asOf: (json['as_of'] ?? '').toString(),
      dueThisPeriod: _toDouble(json['due_this_period']),
      paidThisPeriod: _toDouble(json['paid_this_period']),
      remainingDue: _toDouble(json['remaining_due']),
      totalDebt: _toDouble(json['total_debt']),
      allocatableTargets: rawTargets
          .whereType<Map<String, dynamic>>()
          .map(PaymentAllocationTarget.fromJson)
          .toList(),
    );
  }
}

class PaymentAllocationTarget {
  const PaymentAllocationTarget({
    required this.type,
    required this.id,
    required this.name,
    required this.remainingBalance,
    this.nextDue,
  });

  final String type;
  final String id;
  final String name;
  final double remainingBalance;
  final double? nextDue;

  String get key => '$type::$id';

  factory PaymentAllocationTarget.fromJson(Map<String, dynamic> json) {
    return PaymentAllocationTarget(
      type: (json['type'] ?? '').toString(),
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      remainingBalance: _toDouble(json['remaining_balance']),
      nextDue: json['next_due'] == null ? null : _toDouble(json['next_due']),
    );
  }
}

class PaymentAllocationInput {
  const PaymentAllocationInput({
    required this.targetType,
    required this.targetId,
    required this.amount,
  });

  final String targetType;
  final String targetId;
  final double amount;

  Map<String, dynamic> toJson() {
    return {
      'target_type': targetType,
      'target_id': targetId,
      'amount': amount,
    };
  }
}

class CardPaymentSubmissionResult {
  const CardPaymentSubmissionResult({
    required this.success,
    required this.requiresAllocation,
    this.message,
    this.paymentContext,
  });

  final bool success;
  final bool requiresAllocation;
  final String? message;
  final CardPaymentContext? paymentContext;

  factory CardPaymentSubmissionResult.success({String? message}) {
    return CardPaymentSubmissionResult(
      success: true,
      requiresAllocation: false,
      message: message,
    );
  }

  factory CardPaymentSubmissionResult.failure({
    required String message,
    bool requiresAllocation = false,
    CardPaymentContext? paymentContext,
  }) {
    return CardPaymentSubmissionResult(
      success: false,
      requiresAllocation: requiresAllocation,
      message: message,
      paymentContext: paymentContext,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
