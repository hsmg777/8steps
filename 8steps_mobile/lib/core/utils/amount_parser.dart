class AmountParser {
  static int textToCents(String value) {
    final normalized =
        value.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalized.isEmpty) return 0;
    final amount = double.tryParse(normalized) ?? 0;
    return (amount * 100).round();
  }
}
