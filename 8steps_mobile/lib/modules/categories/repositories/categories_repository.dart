import '../models/app_category.dart';
import '../models/budget_models.dart';

abstract class CategoriesRepository {
  Future<List<AppCategory>> getCategories();
  Future<CategoryMutationResult> createCategory({
    required String name,
    required double monthlyBudget,
    String? month,
  });
  Future<CategoryMutationResult> updateCategory({
    required String categoryId,
    String? name,
    double? monthlyBudget,
    String? month,
  });
  Future<void> deleteCategory(String categoryId);

  Future<List<BudgetStatusItem>> getBudgetStatus(String month);
  Future<List<BudgetAlertItem>> getBudgetAlerts(String month);
  Future<BudgetSummary> getBudgetSummary(String month);
  Future<BudgetAffordability> getBudgetAffordability(String month);
  Future<List<BudgetCarryover>> getCarryovers(String month);
  Future<List<MonthClosure>> getClosures({
    required String from,
    required String to,
  });
}
