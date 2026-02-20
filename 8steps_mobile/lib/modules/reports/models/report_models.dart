class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.totals,
    required this.budgets,
    required this.categories,
    required this.trends,
  });

  final String month;
  final ReportTotals totals;
  final MonthlyBudgetSummary budgets;
  final List<MonthlyCategoryReport> categories;
  final List<MonthlyTrendPoint> trends;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    final categoriesRaw =
        json['categories'] is List ? json['categories'] as List : const [];
    final trendsRaw =
        json['trends'] is List ? json['trends'] as List : const [];

    return MonthlyReport(
      month: (json['month'] ?? '').toString(),
      totals: ReportTotals.fromJson(
        json['totals'] is Map<String, dynamic>
            ? json['totals'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
      budgets: MonthlyBudgetSummary.fromJson(
        json['budgets'] is Map<String, dynamic>
            ? json['budgets'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
      categories: categoriesRaw
          .whereType<Map<String, dynamic>>()
          .map(MonthlyCategoryReport.fromJson)
          .toList(),
      trends: trendsRaw
          .whereType<Map<String, dynamic>>()
          .map(MonthlyTrendPoint.fromJson)
          .toList(),
    );
  }
}

class YearlyReport {
  const YearlyReport({
    required this.year,
    required this.totals,
    required this.monthly,
    required this.categories,
  });

  final int year;
  final YearlyTotals totals;
  final List<YearlyMonthlyPoint> monthly;
  final List<YearlyCategoryReport> categories;

  factory YearlyReport.fromJson(Map<String, dynamic> json) {
    final monthlyRaw =
        json['monthly'] is List ? json['monthly'] as List : const [];
    final categoriesRaw =
        json['categories'] is List ? json['categories'] as List : const [];

    return YearlyReport(
      year: _toInt(json['year']),
      totals: YearlyTotals.fromJson(
        json['totals'] is Map<String, dynamic>
            ? json['totals'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
      monthly: monthlyRaw
          .whereType<Map<String, dynamic>>()
          .map(YearlyMonthlyPoint.fromJson)
          .toList(),
      categories: categoriesRaw
          .whereType<Map<String, dynamic>>()
          .map(YearlyCategoryReport.fromJson)
          .toList(),
    );
  }
}

class ReportTotals {
  const ReportTotals({
    required this.income,
    required this.expense,
    required this.net,
  });

  final double income;
  final double expense;
  final double net;

  factory ReportTotals.fromJson(Map<String, dynamic> json) {
    return ReportTotals(
      income: _toDouble(json['income']),
      expense: _toDouble(json['expense']),
      net: _toDouble(json['net']),
    );
  }
}

class MonthlyBudgetSummary {
  const MonthlyBudgetSummary({
    required this.totalBudgeted,
    required this.totalSpentInCategories,
    required this.variance,
    required this.percentUsed,
  });

  final double totalBudgeted;
  final double totalSpentInCategories;
  final double variance;
  final double percentUsed;

  factory MonthlyBudgetSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyBudgetSummary(
      totalBudgeted: _toDouble(json['totalBudgeted'] ?? json['total_budgeted']),
      totalSpentInCategories: _toDouble(
          json['totalSpentInCategories'] ?? json['total_spent_in_categories']),
      variance: _toDouble(json['variance']),
      percentUsed: _toDouble(json['percentUsed'] ?? json['percent_used']),
    );
  }
}

class MonthlyCategoryReport {
  const MonthlyCategoryReport({
    required this.categoryId,
    required this.categoryName,
    required this.budget,
    required this.spent,
    required this.variance,
    required this.percentUsed,
  });

  final String categoryId;
  final String categoryName;
  final double budget;
  final double spent;
  final double variance;
  final double percentUsed;

  factory MonthlyCategoryReport.fromJson(Map<String, dynamic> json) {
    return MonthlyCategoryReport(
      categoryId: (json['categoryId'] ?? json['category_id'] ?? '').toString(),
      categoryName:
          (json['categoryName'] ?? json['category_name'] ?? 'Categoría')
              .toString(),
      budget: _toDouble(json['budget']),
      spent: _toDouble(json['spent']),
      variance: _toDouble(json['variance']),
      percentUsed: _toDouble(json['percentUsed'] ?? json['percent_used']),
    );
  }
}

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.month,
    required this.income,
    required this.expense,
    required this.net,
    required this.budgeted,
    required this.spentInCategories,
  });

  final String month;
  final double income;
  final double expense;
  final double net;
  final double budgeted;
  final double spentInCategories;

  factory MonthlyTrendPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendPoint(
      month: (json['month'] ?? '').toString(),
      income: _toDouble(json['income']),
      expense: _toDouble(json['expense']),
      net: _toDouble(json['net']),
      budgeted: _toDouble(json['budgeted']),
      spentInCategories:
          _toDouble(json['spentInCategories'] ?? json['spent_in_categories']),
    );
  }
}

class YearlyTotals {
  const YearlyTotals({
    required this.income,
    required this.expense,
    required this.net,
    required this.budgeted,
    required this.spentInCategories,
    required this.budgetVariance,
  });

  final double income;
  final double expense;
  final double net;
  final double budgeted;
  final double spentInCategories;
  final double budgetVariance;

  factory YearlyTotals.fromJson(Map<String, dynamic> json) {
    return YearlyTotals(
      income: _toDouble(json['income']),
      expense: _toDouble(json['expense']),
      net: _toDouble(json['net']),
      budgeted: _toDouble(json['budgeted']),
      spentInCategories:
          _toDouble(json['spentInCategories'] ?? json['spent_in_categories']),
      budgetVariance:
          _toDouble(json['budgetVariance'] ?? json['budget_variance']),
    );
  }
}

class YearlyMonthlyPoint {
  const YearlyMonthlyPoint({
    required this.month,
    required this.income,
    required this.expense,
    required this.net,
    required this.budgeted,
    required this.spentInCategories,
  });

  final String month;
  final double income;
  final double expense;
  final double net;
  final double budgeted;
  final double spentInCategories;

  factory YearlyMonthlyPoint.fromJson(Map<String, dynamic> json) {
    return YearlyMonthlyPoint(
      month: (json['month'] ?? '').toString(),
      income: _toDouble(json['income']),
      expense: _toDouble(json['expense']),
      net: _toDouble(json['net']),
      budgeted: _toDouble(json['budgeted']),
      spentInCategories:
          _toDouble(json['spentInCategories'] ?? json['spent_in_categories']),
    );
  }
}

class YearlyCategoryReport {
  const YearlyCategoryReport({
    required this.categoryId,
    required this.categoryName,
    required this.annualSpent,
    required this.averageMonthlySpent,
    required this.annualBudget,
    required this.variance,
  });

  final String categoryId;
  final String categoryName;
  final double annualSpent;
  final double averageMonthlySpent;
  final double annualBudget;
  final double variance;

  factory YearlyCategoryReport.fromJson(Map<String, dynamic> json) {
    return YearlyCategoryReport(
      categoryId: (json['categoryId'] ?? json['category_id'] ?? '').toString(),
      categoryName:
          (json['categoryName'] ?? json['category_name'] ?? 'Categoría')
              .toString(),
      annualSpent: _toDouble(json['annualSpent'] ?? json['annual_spent']),
      averageMonthlySpent: _toDouble(
          json['averageMonthlySpent'] ?? json['average_monthly_spent']),
      annualBudget: _toDouble(json['annualBudget'] ?? json['annual_budget']),
      variance: _toDouble(json['variance']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
