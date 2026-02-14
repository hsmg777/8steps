class AppSubscription {
  const AppSubscription({
    required this.status,
    required this.premiumUntil,
    required this.provider,
  });

  final String status;
  final DateTime? premiumUntil;
  final String provider;

  bool get isPremium => status == 'ACTIVE';

  factory AppSubscription.fromJson(Map<String, dynamic> json) {
    return AppSubscription(
      status: (json['status'] as String?) ?? 'FREE',
      premiumUntil: json['premiumUntil'] == null
          ? null
          : DateTime.tryParse(json['premiumUntil'] as String),
      provider: (json['provider'] as String?) ?? 'UNKNOWN',
    );
  }
}
