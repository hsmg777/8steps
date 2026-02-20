class AppTransaction {
  const AppTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.occurredAt,
    this.categoryId,
    this.accountId,
    this.categoryName,
    this.accountName,
    this.note,
  });

  final String id;
  final String type;
  final double amount;
  final String? accountId;
  final String? categoryId;
  final DateTime occurredAt;
  final String? note;
  final String? accountName;
  final String? categoryName;

  bool get isExpense => type.toLowerCase() == 'expense';

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'expense').toString(),
      amount: _toDouble(json['amount']),
      accountId: json['accountId']?.toString(),
      categoryId: json['categoryId']?.toString(),
      occurredAt: DateTime.tryParse((json['occurredAt'] ?? '').toString()) ??
          DateTime.now(),
      note: json['note']?.toString(),
      accountName: json['accountName']?.toString(),
      categoryName: json['categoryName']?.toString(),
    );
  }
}

class TransactionsPage {
  const TransactionsPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<AppTransaction> items;
  final int page;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  static const empty = TransactionsPage(items: [], page: 1, totalPages: 1);

  factory TransactionsPage.fromJson(dynamic body) {
    if (body is List<dynamic>) {
      return TransactionsPage(
        items: body
            .whereType<Map<String, dynamic>>()
            .map(AppTransaction.fromJson)
            .toList(),
        page: 1,
        totalPages: 1,
      );
    }

    final map = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final rawItems = (map['transactions'] ?? map['items'] ?? map['data'] ?? [])
        as List<dynamic>;

    return TransactionsPage(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(AppTransaction.fromJson)
          .toList(),
      page: _toInt(map['page'], fallback: 1),
      totalPages: _toInt(map['totalPages'], fallback: 1),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
