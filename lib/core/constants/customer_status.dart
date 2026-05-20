enum CustomerStatus {
  active('ACTIVE', 'Aktif'),
  prospect('PROSPECT', 'Prospect'),
  pending('PENDING', 'Pending'),
  rejected('REJECTED', 'Ditolak'),
  nonactive('NONACTIVE', 'Non-Aktif');

  final String code;
  final String label;
  const CustomerStatus(this.code, this.label);

  static CustomerStatus fromCode(String? code) {
    if (code == null || code.isEmpty) return CustomerStatus.prospect;
    final upper = code.toUpperCase();
    return CustomerStatus.values.firstWhere(
      (s) => s.code == upper,
      orElse: () => CustomerStatus.prospect,
    );
  }
}
