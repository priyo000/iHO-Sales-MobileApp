import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,###', 'id_ID');

  static String currency(dynamic amount) {
    final value = _toDouble(amount);
    return _currencyFormat.format(value);
  }

  static String currencyCompact(dynamic amount) {
    final value = _toDouble(amount);
    if (value.abs() >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (value.abs() >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }
    return _currencyFormat.format(value);
  }

  static String number(dynamic amount) {
    return _numberFormat.format(_toDouble(amount));
  }

  static String date(DateTime? value, {String pattern = 'dd MMM yyyy'}) {
    if (value == null) return '-';
    return DateFormat(pattern, 'id_ID').format(value);
  }

  static String dateFromString(String? iso, {String pattern = 'dd MMM yyyy'}) {
    if (iso == null || iso.isEmpty) return '-';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '-';
    return DateFormat(pattern, 'id_ID').format(parsed);
  }

  static String dateFromEpochMs(int? epochMs, {String pattern = 'dd MMM yyyy'}) {
    if (epochMs == null) return '-';
    return DateFormat(
      pattern,
      'id_ID',
    ).format(DateTime.fromMillisecondsSinceEpoch(epochMs));
  }

  static String dateTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(value);
  }

  static String relativeTime(DateTime? value) {
    if (value == null) return '-';
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return date(value);
  }

  static String nowServerIso() => DateTime.now().toUtc().toIso8601String();

  static String toServerIso(DateTime dt) => dt.toUtc().toIso8601String();

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
