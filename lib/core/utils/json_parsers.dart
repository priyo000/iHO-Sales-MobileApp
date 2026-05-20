int? parseIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

int parseIntOr(dynamic value, int defaultValue) {
  return parseIntOrNull(value) ?? defaultValue;
}

double? parseDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double parseDoubleOr(dynamic value, double defaultValue) {
  return parseDoubleOrNull(value) ?? defaultValue;
}

int? parseIsoToEpochMs(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    return parsed?.millisecondsSinceEpoch;
  }
  return null;
}

DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String? parseStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

bool parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes';
  }
  return false;
}
