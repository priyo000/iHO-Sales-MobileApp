enum VisitStatus {
  belumDikunjungi('BELUM_DIKUNJUNGI', 'Belum Dikunjungi'),
  dikunjungi('DIKUNJUNGI', 'Dikunjungi'),
  selesai('SELESAI', 'Selesai'),
  dibatalkan('DIBATALKAN', 'Dibatalkan');

  final String code;
  final String label;
  const VisitStatus(this.code, this.label);

  static VisitStatus fromCode(String? code) {
    if (code == null) return VisitStatus.belumDikunjungi;
    return VisitStatus.values.firstWhere(
      (s) => s.code == code.toUpperCase(),
      orElse: () => VisitStatus.belumDikunjungi,
    );
  }
}

typedef ScheduleStatus = VisitStatus;

enum CheckoutReason {
  tokoTutup('Toko Tutup'),
  pemilikTidakAda('Pemilik Tidak Ada'),
  stokPenuh('Stok Penuh'),
  lainnya('Lainnya');

  final String label;
  const CheckoutReason(this.label);

  static List<String> get allLabels =>
      CheckoutReason.values.map((r) => r.label).toList();
}
