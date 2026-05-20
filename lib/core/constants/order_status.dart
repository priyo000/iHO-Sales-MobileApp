enum OrderStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  success('SUCCESS'),
  cancelled('CANCELLED'),
  failed('FAILED');

  final String code;
  const OrderStatus(this.code);

  static OrderStatus fromCode(String? code) {
    if (code == null) return OrderStatus.pending;
    final upper = code.toUpperCase();
    return OrderStatus.values.firstWhere(
      (s) => s.code == upper,
      orElse: () => OrderStatus.pending,
    );
  }

  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.processing => 'Diproses',
    OrderStatus.success => 'Berhasil',
    OrderStatus.cancelled => 'Dibatalkan',
    OrderStatus.failed => 'Gagal',
  };
}
