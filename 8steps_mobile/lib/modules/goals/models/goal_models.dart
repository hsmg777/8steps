class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.targetDate,
    required this.status,
    required this.savedAmount,
    required this.progressPercent,
    this.savingsAccountId,
  });

  final String id;
  final String name;
  final String type;
  final double targetAmount;
  final DateTime? targetDate;
  final String status;
  final double savedAmount;
  final double progressPercent;
  final String? savingsAccountId;

  factory Goal.fromJson(Map<String, dynamic> json) {
    final savings = json['savings_account'] is Map<String, dynamic>
        ? json['savings_account'] as Map<String, dynamic>
        : (json['savingsAccount'] is Map<String, dynamic>
            ? json['savingsAccount'] as Map<String, dynamic>
            : const <String, dynamic>{});

    final saved = _toDouble(
      json['savedAmount'] ??
          json['saved_amount'] ??
          savings['balance'] ??
          savings['currentBalance'] ??
          0,
    );
    final target = _toDouble(json['targetAmount'] ?? json['target_amount']);
    final computedPercent = target <= 0 ? 0.0 : (saved / target) * 100;

    return Goal(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Meta').toString(),
      type: (json['type'] ?? 'custom').toString(),
      targetAmount: target,
      targetDate: DateTime.tryParse(
        (json['targetDate'] ?? json['target_date'] ?? '').toString(),
      ),
      status: (json['status'] ?? 'active').toString(),
      savedAmount: saved,
      progressPercent:
          _toDouble(json['progressPercent'] ?? json['progress_percent']) > 0
              ? _toDouble(json['progressPercent'] ?? json['progress_percent'])
              : computedPercent,
      savingsAccountId:
          savings['id']?.toString() ?? json['savingsAccountId']?.toString(),
    );
  }
}

class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  factory GoalContribution.fromJson(Map<String, dynamic> json) {
    return GoalContribution(
      id: (json['id'] ?? '').toString(),
      amount: _toDouble(json['amount']),
      date: DateTime.tryParse(
            (json['date'] ?? json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      note: json['note']?.toString(),
    );
  }
}

class GoalAutoContribution {
  const GoalAutoContribution({
    required this.id,
    required this.fromAccountId,
    required this.amount,
    required this.frequency,
    this.dayOfMonth,
    this.nextRunDate,
    required this.enabled,
  });

  final String id;
  final String fromAccountId;
  final double amount;
  final String frequency;
  final int? dayOfMonth;
  final DateTime? nextRunDate;
  final bool enabled;

  factory GoalAutoContribution.fromJson(Map<String, dynamic> json) {
    return GoalAutoContribution(
      id: (json['id'] ?? '').toString(),
      fromAccountId:
          (json['fromAccountId'] ?? json['from_account_id'] ?? '').toString(),
      amount: _toDouble(json['amount']),
      frequency: (json['frequency'] ?? 'monthly').toString(),
      dayOfMonth: json['dayOfMonth'] is num
          ? (json['dayOfMonth'] as num).toInt()
          : (json['day_of_month'] is num
              ? (json['day_of_month'] as num).toInt()
              : null),
      nextRunDate: DateTime.tryParse(
        (json['nextRunDate'] ?? json['next_run_date'] ?? '').toString(),
      ),
      enabled: json['enabled'] == true,
    );
  }
}

class GoalDetail {
  const GoalDetail({
    required this.goal,
    this.autoContribution,
  });

  final Goal goal;
  final GoalAutoContribution? autoContribution;
}

class GoalRecommendationResult {
  const GoalRecommendationResult({
    required this.asOf,
    required this.goal,
    required this.recommendation,
    required this.categoryCuts,
    required this.scenarios,
    required this.cardOptions,
    this.cardDeferralAlternative,
  });

  final DateTime? asOf;
  final GoalRecommendationGoal goal;
  final GoalRecommendationMetrics recommendation;
  final List<GoalCategoryCut> categoryCuts;
  final List<GoalRecommendationScenario> scenarios;
  final List<GoalCardOption> cardOptions;
  final GoalCardDeferralAlternative? cardDeferralAlternative;

  factory GoalRecommendationResult.fromJson(Map<String, dynamic> json) {
    final goalJson = json['goal'] is Map<String, dynamic>
        ? json['goal'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final recommendationJson = json['recommendation'] is Map<String, dynamic>
        ? json['recommendation'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final cuts = json['categoryCuts'] is List
        ? json['categoryCuts'] as List
        : (json['category_cuts'] is List ? json['category_cuts'] as List : []);
    final scenariosRaw =
        json['scenarios'] is List ? json['scenarios'] as List : const [];
    final cardOptionsRaw = json['cardOptions'] is List
        ? json['cardOptions'] as List
        : (json['card_options'] is List ? json['card_options'] as List : []);
    final cardJson = json['cardDeferralAlternative'] is Map<String, dynamic>
        ? json['cardDeferralAlternative'] as Map<String, dynamic>
        : (json['card_deferral_alternative'] is Map<String, dynamic>
            ? json['card_deferral_alternative'] as Map<String, dynamic>
            : null);

    return GoalRecommendationResult(
      asOf: DateTime.tryParse((json['asOf'] ?? json['as_of'] ?? '').toString()),
      goal: GoalRecommendationGoal.fromJson(goalJson),
      recommendation: GoalRecommendationMetrics.fromJson(recommendationJson),
      categoryCuts: cuts
          .whereType<Map<String, dynamic>>()
          .map(GoalCategoryCut.fromJson)
          .toList(),
      scenarios: scenariosRaw
          .whereType<Map<String, dynamic>>()
          .map(GoalRecommendationScenario.fromJson)
          .toList(),
      cardOptions: cardOptionsRaw
          .whereType<Map<String, dynamic>>()
          .map(GoalCardOption.fromJson)
          .toList(),
      cardDeferralAlternative: cardJson == null
          ? null
          : GoalCardDeferralAlternative.fromJson(cardJson),
    );
  }
}

class GoalRecommendationGoal {
  const GoalRecommendationGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.remainingAmount,
    this.targetDate,
    required this.monthsToTarget,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final double remainingAmount;
  final DateTime? targetDate;
  final int monthsToTarget;

  factory GoalRecommendationGoal.fromJson(Map<String, dynamic> json) {
    return GoalRecommendationGoal(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Meta').toString(),
      targetAmount: _toDouble(json['targetAmount'] ?? json['target_amount']),
      savedAmount: _toDouble(json['savedAmount'] ?? json['saved_amount']),
      remainingAmount:
          _toDouble(json['remainingAmount'] ?? json['remaining_amount']),
      targetDate: DateTime.tryParse(
        (json['targetDate'] ?? json['target_date'] ?? '').toString(),
      ),
      monthsToTarget: (json['monthsToTarget'] ?? json['months_to_target'] ?? 0)
              is num
          ? ((json['monthsToTarget'] ?? json['months_to_target'] ?? 0) as num)
              .toInt()
          : 0,
    );
  }
}

class GoalRecommendationMetrics {
  const GoalRecommendationMetrics({
    required this.recommendedMonthlySaving,
    required this.monthlyCapacity,
    required this.immediateCapacity,
    required this.realMonthlyCapacity,
    required this.flowMonthlyCapacity,
    required this.cashAvailableNow,
    required this.obligationsDueBeforeNextIncome,
    this.nextIncomeDate,
    required this.committedToOtherGoals,
    required this.expectedRecurringIncome,
    required this.averageVariableIncome,
    required this.averageVariableExpense,
    required this.fixedObligations,
    required this.projectedMonthsToGoal,
    this.projectedFinishDate,
    this.configuredAutoMonthlySaving,
    this.configuredPlanStatus,
    this.configuredPlanRequiredGap,
    this.configuredProjectedFinishDate,
  });

  final double recommendedMonthlySaving;
  final double monthlyCapacity;
  final double immediateCapacity;
  final double realMonthlyCapacity;
  final double flowMonthlyCapacity;
  final double cashAvailableNow;
  final double obligationsDueBeforeNextIncome;
  final DateTime? nextIncomeDate;
  final double committedToOtherGoals;
  final double expectedRecurringIncome;
  final double averageVariableIncome;
  final double averageVariableExpense;
  final double fixedObligations;
  final int projectedMonthsToGoal;
  final DateTime? projectedFinishDate;
  final double? configuredAutoMonthlySaving;
  final String? configuredPlanStatus;
  final double? configuredPlanRequiredGap;
  final DateTime? configuredProjectedFinishDate;

  factory GoalRecommendationMetrics.fromJson(Map<String, dynamic> json) {
    final monthlyCapacity =
        _toDouble(json['monthlyCapacity'] ?? json['monthly_capacity']);
    final realCapacity = _toDouble(
      json['realMonthlyCapacity'] ?? json['real_monthly_capacity'],
    );
    return GoalRecommendationMetrics(
      recommendedMonthlySaving: _toDouble(
        json['recommendedMonthlySaving'] ?? json['recommended_monthly_saving'],
      ),
      monthlyCapacity: monthlyCapacity > 0 ? monthlyCapacity : realCapacity,
      immediateCapacity:
          _toDouble(json['immediateCapacity'] ?? json['immediate_capacity']),
      realMonthlyCapacity: realCapacity > 0 ? realCapacity : monthlyCapacity,
      flowMonthlyCapacity: _toDouble(
          json['flowMonthlyCapacity'] ?? json['flow_monthly_capacity']),
      cashAvailableNow:
          _toDouble(json['cashAvailableNow'] ?? json['cash_available_now']),
      obligationsDueBeforeNextIncome: _toDouble(
        json['obligationsDueBeforeNextIncome'] ??
            json['obligations_due_before_next_income'],
      ),
      nextIncomeDate: DateTime.tryParse(
        (json['nextIncomeDate'] ?? json['next_income_date'] ?? '').toString(),
      ),
      committedToOtherGoals: _toDouble(
        json['committedToOtherGoals'] ?? json['committed_to_other_goals'],
      ),
      expectedRecurringIncome: _toDouble(
        json['expectedRecurringIncome'] ?? json['expected_recurring_income'],
      ),
      averageVariableIncome: _toDouble(
        json['averageVariableIncome'] ?? json['average_variable_income'],
      ),
      averageVariableExpense: _toDouble(
        json['averageVariableExpense'] ?? json['average_variable_expense'],
      ),
      fixedObligations:
          _toDouble(json['fixedObligations'] ?? json['fixed_obligations']),
      projectedMonthsToGoal: (json['projectedMonthsToGoal'] ??
              json['projected_months_to_goal'] ??
              0) is num
          ? ((json['projectedMonthsToGoal'] ??
                  json['projected_months_to_goal'] ??
                  0) as num)
              .toInt()
          : 0,
      projectedFinishDate: DateTime.tryParse(
        (json['projectedFinishDate'] ?? json['projected_finish_date'] ?? '')
            .toString(),
      ),
      configuredAutoMonthlySaving:
          json.containsKey('configuredAutoMonthlySaving') ||
                  json.containsKey('configured_auto_monthly_saving')
              ? _toDouble(
                  json['configuredAutoMonthlySaving'] ??
                      json['configured_auto_monthly_saving'],
                )
              : null,
      configuredPlanStatus:
          (json['configuredPlanStatus'] ?? json['configured_plan_status'])
              ?.toString(),
      configuredPlanRequiredGap:
          json.containsKey('configuredPlanRequiredGap') ||
                  json.containsKey('configured_plan_required_gap')
              ? _toDouble(
                  json['configuredPlanRequiredGap'] ??
                      json['configured_plan_required_gap'],
                )
              : null,
      configuredProjectedFinishDate: DateTime.tryParse(
        (json['configuredProjectedFinishDate'] ??
                json['configured_projected_finish_date'] ??
                '')
            .toString(),
      ),
    );
  }
}

class GoalCategoryCut {
  const GoalCategoryCut({
    required this.categoryId,
    required this.categoryName,
    required this.spent,
    required this.budget,
    required this.avgMonthlySpent,
    required this.suggestedCut,
    required this.impactMonthsReduced,
  });

  final String categoryId;
  final String categoryName;
  final double spent;
  final double budget;
  final double avgMonthlySpent;
  final double suggestedCut;
  final int impactMonthsReduced;

  factory GoalCategoryCut.fromJson(Map<String, dynamic> json) {
    return GoalCategoryCut(
      categoryId: (json['categoryId'] ?? json['category_id'] ?? '').toString(),
      categoryName:
          (json['categoryName'] ?? json['category_name'] ?? 'Categoría')
              .toString(),
      spent: _toDouble(json['spent']),
      budget: _toDouble(json['budget']),
      avgMonthlySpent:
          _toDouble(json['avgMonthlySpent'] ?? json['avg_monthly_spent']),
      suggestedCut: _toDouble(json['suggestedCut'] ?? json['suggested_cut']),
      impactMonthsReduced: (json['impactMonthsReduced'] ??
              json['impact_months_reduced'] ??
              0) is num
          ? ((json['impactMonthsReduced'] ?? json['impact_months_reduced'] ?? 0)
                  as num)
              .toInt()
          : 0,
    );
  }
}

class GoalRecommendationScenario {
  const GoalRecommendationScenario({
    required this.type,
    required this.monthlySave,
    this.estimatedFinishDate,
    required this.gapRemaining,
  });

  final String type;
  final double monthlySave;
  final DateTime? estimatedFinishDate;
  final double gapRemaining;

  factory GoalRecommendationScenario.fromJson(Map<String, dynamic> json) {
    return GoalRecommendationScenario(
      type: (json['type'] ?? '').toString(),
      monthlySave: _toDouble(json['monthlySave'] ?? json['monthly_save']),
      estimatedFinishDate: DateTime.tryParse(
        (json['estimatedFinishDate'] ?? json['estimated_finish_date'] ?? '')
            .toString(),
      ),
      gapRemaining: _toDouble(json['gapRemaining'] ?? json['gap_remaining']),
    );
  }
}

class GoalCardOption {
  const GoalCardOption({
    required this.cardId,
    required this.cardName,
    required this.availableLimit,
    required this.suggestedInstallments,
    required this.estimatedInstallment,
    required this.utilizationAfter,
    required this.monthlyCapacityAfter,
    required this.eligible,
    required this.reason,
  });

  final String cardId;
  final String cardName;
  final double availableLimit;
  final int suggestedInstallments;
  final double estimatedInstallment;
  final double utilizationAfter;
  final double monthlyCapacityAfter;
  final bool eligible;
  final String reason;

  factory GoalCardOption.fromJson(Map<String, dynamic> json) {
    return GoalCardOption(
      cardId: (json['cardId'] ?? json['card_id'] ?? '').toString(),
      cardName: (json['cardName'] ?? json['card_name'] ?? 'Tarjeta').toString(),
      availableLimit:
          _toDouble(json['availableLimit'] ?? json['available_limit']),
      suggestedInstallments: (json['suggestedInstallments'] ??
              json['suggested_installments'] ??
              0) is num
          ? ((json['suggestedInstallments'] ??
                  json['suggested_installments'] ??
                  0) as num)
              .toInt()
          : 0,
      estimatedInstallment: _toDouble(
        json['estimatedInstallment'] ?? json['estimated_installment'],
      ),
      utilizationAfter:
          _toDouble(json['utilizationAfter'] ?? json['utilization_after']),
      monthlyCapacityAfter: _toDouble(
        json['monthlyCapacityAfter'] ?? json['monthly_capacity_after'],
      ),
      eligible: json['eligible'] == true,
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

class GoalCardDeferralAlternative {
  const GoalCardDeferralAlternative({
    required this.feasible,
    required this.availableCardLimit,
    required this.suggestedInstallments,
    required this.projectedInstallmentAmount,
    required this.reason,
  });

  final bool feasible;
  final double availableCardLimit;
  final int suggestedInstallments;
  final double projectedInstallmentAmount;
  final String reason;

  factory GoalCardDeferralAlternative.fromJson(Map<String, dynamic> json) {
    return GoalCardDeferralAlternative(
      feasible: json['feasible'] == true,
      availableCardLimit:
          _toDouble(json['availableCardLimit'] ?? json['available_card_limit']),
      suggestedInstallments: (json['suggestedInstallments'] ??
              json['suggested_installments'] ??
              0) is num
          ? ((json['suggestedInstallments'] ??
                  json['suggested_installments'] ??
                  0) as num)
              .toInt()
          : 0,
      projectedInstallmentAmount: _toDouble(
        json['projectedInstallmentAmount'] ??
            json['projected_installment_amount'],
      ),
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
