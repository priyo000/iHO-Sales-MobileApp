import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(dynamic amount) {
    if (amount == null) return 'Rp 0';

    double value = 0.0;
    if (amount is int) {
      value = amount.toDouble();
    } else if (amount is double) {
      value = amount;
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return formatter.format(value);
  }
}
