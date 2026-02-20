class RecurrentExpense {
  const RecurrentExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.startAt,
    required this.method,
    required this.status,
    this.accountId,
    this.cardId,
    this.categoryId,
    this.note,
  });

  final String id;
  final String name;
  final double amount;
  final String frequency;
  final DateTime startAt;
  final String method;
  final String status;
  final String? accountId;
  final String? cardId;
  final String? categoryId;
  final String? note;

  factory RecurrentExpense.fromJson(Map<String, dynamic> json) {
    return RecurrentExpense(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Gasto recurrente').toString(),
      amount: _toDouble(json['amount']),
      frequency: (json['frequency'] ?? 'monthly').toString().toLowerCase(),
      startAt: DateTime.tryParse(
            (json['startAt'] ?? json['start_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      method: (json['method'] ?? 'account').toString().toLowerCase(),
      status: (json['status'] ?? 'active').toString().toLowerCase(),
      accountId:
          json['accountId']?.toString() ?? json['account_id']?.toString(),
      cardId: json['cardId']?.toString() ?? json['card_id']?.toString(),
      categoryId:
          json['categoryId']?.toString() ?? json['category_id']?.toString(),
      note: json['note']?.toString(),
    );
  }
}

class RecurrentIncome {
  const RecurrentIncome({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.startAt,
    required this.status,
    this.accountId,
    this.note,
  });

  final String id;
  final String name;
  final double amount;
  final String frequency;
  final DateTime startAt;
  final String status;
  final String? accountId;
  final String? note;

  factory RecurrentIncome.fromJson(Map<String, dynamic> json) {
    return RecurrentIncome(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Ingreso recurrente').toString(),
      amount: _toDouble(json['amount']),
      frequency: (json['frequency'] ?? 'monthly').toString().toLowerCase(),
      startAt: DateTime.tryParse(
            (json['startAt'] ?? json['start_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      status: (json['status'] ?? 'active').toString().toLowerCase(),
      accountId:
          json['accountId']?.toString() ?? json['account_id']?.toString(),
      note: json['note']?.toString(),
    );
  }
}

const recurringFrequencies = <String>[
  'monthly',
  'quarterly',
  'semiannual',
  'annual',
];

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
