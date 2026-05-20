enum PaymentSystem {
  cash('Cash'),
  credit('Credit');

  final String code;
  const PaymentSystem(this.code);

  static PaymentSystem? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    final lower = code.toLowerCase();
    return PaymentSystem.values.firstWhere(
      (p) => p.code.toLowerCase() == lower || p.name == lower,
      orElse: () => PaymentSystem.cash,
    );
  }
}

enum PaymentMethod {
  tunai('Tunai'),
  transfer('Transfer'),
  giro('Giro');

  final String code;
  const PaymentMethod(this.code);

  static PaymentMethod? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return PaymentMethod.values.firstWhere(
      (p) => p.code.toLowerCase() == code.toLowerCase(),
      orElse: () => PaymentMethod.tunai,
    );
  }
}
