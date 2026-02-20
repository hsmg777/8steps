import '../../../services/categories/categories_service.dart';
import '../models/app_category.dart';
import '../models/budget_models.dart';
import 'categories_repository.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  CategoriesRepositoryImpl(this._service);

  final CategoriesService _service;

  @override
  Future<List<AppCategory>> getCategories() => _service.getCategories();

  @override
  Future<CategoryMutationResult> createCategory({
    required String name,
    required double monthlyBudget,
    String? month,
  }) {
    return _service.createCategory(
      name: name,
      monthlyBudget: monthlyBudget,
      month: month,
    );
  }

  @override
  Future<CategoryMutationResult> updateCategory({
    required String categoryId,
    String? name,
    double? monthlyBudget,
    String? month,
  }) {
    return _service.updateCategory(
      categoryId: categoryId,
      name: name,
      monthlyBudget: monthlyBudget,
      month: month,
    );
  }

  @override
  Future<void> deleteCategory(String categoryId) {
    return _service.deleteCategory(categoryId);
  }

  @override
  Future<List<BudgetStatusItem>> getBudgetStatus(String month) {
    return _service.getBudgetStatus(month);
  }

  @override
  Future<List<BudgetAlertItem>> getBudgetAlerts(String month) {
    return _service.getBudgetAlerts(month);
  }

  @override
  Future<BudgetSummary> getBudgetSummary(String month) {
    return _service.getBudgetSummary(month);
  }

  @override
  Future<BudgetAffordability> getBudgetAffordability(String month) {
    return _service.getBudgetAffordability(month);
  }

  @override
  Future<List<BudgetCarryover>> getCarryovers(String month) {
    return _service.getCarryovers(month);
  }

  @override
  Future<List<MonthClosure>> getClosures({
    required String from,
    required String to,
  }) {
    return _service.getClosures(from: from, to: to);
  }
}
