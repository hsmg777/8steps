class AppAccount {
  const AppAccount({
    required this.id,
    required this.name,
    required this.balance,
    required this.status,
  });

  final String id;
  final String name;
  final double balance;
  final String status;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory AppAccount.fromJson(Map<String, dynamic> json) {
    return AppAccount(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Cuenta').toString(),
      balance: _readBalance(json),
      status: (json['status'] ?? 'ACTIVE').toString(),
    );
  }

  static double _readBalance(Map<String, dynamic> json) {
    final dynamic candidate = json['balance'] ??
        json['currentBalance'] ??
        json['initialBalance'] ??
        0;
    if (candidate is num) return candidate.toDouble();
    return double.tryParse(candidate.toString()) ?? 0;
  }
}
