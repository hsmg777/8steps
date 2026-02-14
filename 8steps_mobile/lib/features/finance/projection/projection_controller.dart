import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectionState {
  final int targetCents;
  final int months;
  final int monthlySavingCents;

  const ProjectionState({
    this.targetCents = 0,
    this.months = 1,
    this.monthlySavingCents = 0,
  });

  int get requiredMonthlyForTarget {
    if (months <= 0) return 0;
    return (targetCents / months).ceil();
  }

  int get projectedByMonthly {
    if (months <= 0) return 0;
    return monthlySavingCents * months;
  }

  ProjectionState copyWith({
    int? targetCents,
    int? months,
    int? monthlySavingCents,
  }) {
    return ProjectionState(
      targetCents: targetCents ?? this.targetCents,
      months: months ?? this.months,
      monthlySavingCents: monthlySavingCents ?? this.monthlySavingCents,
    );
  }
}

class ProjectionController extends StateNotifier<ProjectionState> {
  ProjectionController() : super(const ProjectionState());

  void setTarget(int cents) => state = state.copyWith(targetCents: cents);

  void setMonths(int months) => state = state.copyWith(months: months);

  void setMonthlySaving(int cents) =>
      state = state.copyWith(monthlySavingCents: cents);
}

final projectionControllerProvider =
    StateNotifierProvider<ProjectionController, ProjectionState>(
  (ref) => ProjectionController(),
);
