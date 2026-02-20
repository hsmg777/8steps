class BudgetStatusItem {
  const BudgetStatusItem({
    required this.categoryId,
    required this.categoryName,
    required this.budget,
    required this.carryoverAdjustment,
    required this.effectiveBudget,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
    required this.alertLevel,
  });

  final String categoryId;
  final String categoryName;
  final double budget;
  final double carryoverAdjustment;
  final double effectiveBudget;
  final double spent;
  final double remaining;
  final double percentUsed;
  final String alertLevel;

  factory BudgetStatusItem.fromJson(Map<String, dynamic> json) {
    return BudgetStatusItem(
      categoryId: (json['categoryId'] ?? json['id'] ?? '').toString(),
      categoryName:
          (json['categoryName'] ?? json['name'] ?? 'Categoría').toString(),
      budget: _toDouble(json['budget']),
      carryoverAdjustment: _toDouble(json['carryoverAdjustment']),
      effectiveBudget: _toDouble(json['effectiveBudget']),
      spent: _toDouble(json['spent']),
      remaining: _toDouble(json['remaining']),
      percentUsed: _toDouble(json['percentUsed']),
      alertLevel: (json['alertLevel'] ?? 'NONE').toString(),
    );
  }
}

class BudgetAlertItem {
  const BudgetAlertItem({
    required this.categoryName,
    required this.alertLevel,
    required this.percentUsed,
  });

  final String categoryName;
  final String alertLevel;
  final double percentUsed;

  factory BudgetAlertItem.fromJson(Map<String, dynamic> json) {
    return BudgetAlertItem(
      categoryName:
          (json['categoryName'] ?? json['name'] ?? 'Categoría').toString(),
      alertLevel: (json['alertLevel'] ?? 'NONE').toString(),
      percentUsed: _toDouble(json['percentUsed']),
    );
  }
}

class BudgetSummary {
  const BudgetSummary({
    required this.count70,
    required this.count90,
    required this.count100,
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.top3,
  });

  final int count70;
  final int count90;
  final int count100;
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final List<String> top3;

  static const empty = BudgetSummary(
    count70: 0,
    count90: 0,
    count100: 0,
    totalBudget: 0,
    totalSpent: 0,
    totalRemaining: 0,
    top3: [],
  );

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    final counts =
        (json['counts'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final totals =
        (json['totals'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final top = (json['topConsumedCategories'] ??
        json['top3'] ??
        json['topConsumed'] ??
        []) as List<dynamic>;
    return BudgetSummary(
      count70: _toInt(counts['alert70'] ?? json['count70']),
      count90: _toInt(counts['alert90'] ?? json['count90']),
      count100: _toInt(counts['alert100'] ?? json['count100']),
      totalBudget: _toDouble(totals['budget'] ?? json['totalBudget']),
      totalSpent: _toDouble(totals['spent'] ?? json['totalSpent']),
      totalRemaining: _toDouble(
        json['totalRemaining'] ??
            ((totals['budget'] ?? 0) - (totals['spent'] ?? 0)),
      ),
      top3: top
          .map((e) {
            if (e is String) return e;
            if (e is Map<String, dynamic>) {
              return (e['categoryName'] ?? e['name'] ?? '').toString();
            }
            return '';
          })
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList(),
    );
  }
}

class BudgetCarryover {
  const BudgetCarryover({
    this.categoryId,
    required this.categoryName,
    required this.amount,
  });

  final String? categoryId;
  final String categoryName;
  final double amount;

  factory BudgetCarryover.fromJson(Map<String, dynamic> json) {
    return BudgetCarryover(
      categoryId:
          json['categoryId']?.toString() ?? json['category_id']?.toString(),
      categoryName:
          (json['categoryName'] ?? json['name'] ?? 'Categoría').toString(),
      amount: _toDouble(json['amount']),
    );
  }
}

class MonthClosure {
  const MonthClosure({
    required this.month,
    required this.status,
    required this.closedAt,
  });

  final String month;
  final String status;
  final DateTime? closedAt;

  factory MonthClosure.fromJson(Map<String, dynamic> json) {
    return MonthClosure(
      month: (json['month'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.tryParse(json['closedAt'].toString()),
    );
  }
}

class BudgetAffordability {
  const BudgetAffordability({
    required this.month,
    required this.expectedIncome,
    required this.fixedObligations,
    required this.committedSavings,
    required this.cushion,
    required this.recommendedBudgetTotal,
    required this.alreadyBudgetedTotal,
    required this.remainingToBudget,
  });

  final String month;
  final double expectedIncome;
  final double fixedObligations;
  final double committedSavings;
  final double cushion;
  final double recommendedBudgetTotal;
  final double alreadyBudgetedTotal;
  final double remainingToBudget;

  static const empty = BudgetAffordability(
    month: '',
    expectedIncome: 0,
    fixedObligations: 0,
    committedSavings: 0,
    cushion: 0,
    recommendedBudgetTotal: 0,
    alreadyBudgetedTotal: 0,
    remainingToBudget: 0,
  );

  factory BudgetAffordability.fromJson(Map<String, dynamic> json) {
    return BudgetAffordability(
      month: (json['month'] ?? '').toString(),
      expectedIncome:
          _toDouble(json['expected_income'] ?? json['expectedIncome']),
      fixedObligations: _toDouble(
        json['fixed_obligations'] ?? json['fixedObligations'],
      ),
      committedSavings: _toDouble(
        json['committed_savings'] ?? json['committedSavings'],
      ),
      cushion: _toDouble(json['cushion']),
      recommendedBudgetTotal: _toDouble(
        json['recommended_budget_total'] ?? json['recommendedBudgetTotal'],
      ),
      alreadyBudgetedTotal: _toDouble(
        json['already_budgeted_total'] ?? json['alreadyBudgetedTotal'],
      ),
      remainingToBudget: _toDouble(
        json['remaining_to_budget'] ?? json['remainingToBudget'],
      ),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
