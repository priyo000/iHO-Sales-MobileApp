class SyncServerException implements Exception {
  final String message;
  final int statusCode;
  SyncServerException(this.message, this.statusCode);
  @override
  String toString() => '$message (Status: $statusCode)';
}

class SyncDeferredException implements Exception {
  final String reason;
  SyncDeferredException(this.reason);
  @override
  String toString() => 'Deferred: $reason';
}
