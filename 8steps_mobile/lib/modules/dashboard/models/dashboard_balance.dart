class DashboardBalance {
  const DashboardBalance({
    required this.cashAvailable,
    required this.cardDebtTotal,
    required this.netWorthSimple,
  });

  final double cashAvailable;
  final double cardDebtTotal;
  final double netWorthSimple;

  static const empty = DashboardBalance(
    cashAvailable: 0,
    cardDebtTotal: 0,
    netWorthSimple: 0,
  );

  factory DashboardBalance.fromJson(Map<String, dynamic> json) {
    return DashboardBalance(
      cashAvailable: _toDouble(
        json['cash_available'] ?? json['cashAvailable'],
      ),
      cardDebtTotal: _toDouble(
        json['card_debt_total'] ?? json['cardDebtTotal'],
      ),
      netWorthSimple: _toDouble(
        json['net_worth_simple'] ?? json['netWorthSimple'],
      ),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
