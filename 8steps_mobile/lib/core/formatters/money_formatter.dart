import 'package:intl/intl.dart';

class MoneyFormatter {
  static final _currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  static String formatCents(int cents) {
    return _currency.format(cents / 100);
  }
}
