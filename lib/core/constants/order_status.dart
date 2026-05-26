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

  static OrderStatus? fromLabel(String label) {
    for (final s in OrderStatus.values) {
      if (s.label.toLowerCase() == label.toLowerCase()) return s;
    }
    return null;
  }

  String get label => switch (this) {
    OrderStatus.pending => 'Tertunda',
    OrderStatus.processing => 'Diproses',
    OrderStatus.success => 'Berhasil',
    OrderStatus.cancelled => 'Dibatalkan',
    OrderStatus.failed => 'Gagal',
  };
}
