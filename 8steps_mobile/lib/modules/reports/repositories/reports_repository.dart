import '../models/report_models.dart';

abstract class ReportsRepository {
  Future<MonthlyReport> getMonthlyReport({required String month});

  Future<YearlyReport> getYearlyReport({required int year});
}
