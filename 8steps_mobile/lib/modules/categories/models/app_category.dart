class AppCategory {
  const AppCategory({
    required this.id,
    required this.name,
    required this.monthlyBudget,
  });

  final String id;
  final String name;
  final double monthlyBudget;

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Categoría').toString(),
      monthlyBudget: _toDouble(json['monthlyBudget'] ?? json['budget'] ?? 0),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class CategoryWarning {
  const CategoryWarning({
    required this.code,
    required this.message,
    this.month,
    this.recommendedBudgetTotal,
    this.attemptedTotalBudget,
    this.remainingToBudget,
    this.overBy,
  });

  final String code;
  final String message;
  final String? month;
  final double? recommendedBudgetTotal;
  final double? attemptedTotalBudget;
  final double? remainingToBudget;
  final double? overBy;

  factory CategoryWarning.fromJson(Map<String, dynamic> json) {
    final details = json['details'] is Map<String, dynamic>
        ? json['details'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return CategoryWarning(
      code: (json['code'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      month: (details['month'] ?? json['month'])?.toString(),
      recommendedBudgetTotal: _toDoubleOrNull(
        details['recommendedBudgetTotal'] ??
            details['recommended_budget_total'],
      ),
      attemptedTotalBudget: _toDoubleOrNull(
        details['attemptedTotalBudget'] ?? details['attempted_total_budget'],
      ),
      remainingToBudget: _toDoubleOrNull(
        details['remainingToBudget'] ?? details['remaining_to_budget'],
      ),
      overBy: _toDoubleOrNull(details['overBy'] ?? details['over_by']),
    );
  }
}

class CategoryMutationResult {
  const CategoryMutationResult({
    required this.category,
    this.warning,
  });

  final AppCategory category;
  final CategoryWarning? warning;
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
