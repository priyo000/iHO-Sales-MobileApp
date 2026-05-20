class Customer {
  final String id;
  final String? localRef;
  final String? kodePelanggan;
  final String? namaToko;
  final String? namaPemilik;
  final String? noHpPribadi;
  final String? alamatUsaha;
  final double? latitude;
  final double? longitude;
  final String? status;
  final String? fotoTokoUrl;
  final String? fotoKtpPath;
  final bool isLocal;
  final int? createdAt;
  final Map<String, dynamic> extraData;

  const Customer({
    required this.id,
    this.localRef,
    this.kodePelanggan,
    this.namaToko,
    this.namaPemilik,
    this.noHpPribadi,
    this.alamatUsaha,
    this.latitude,
    this.longitude,
    this.status,
    this.fotoTokoUrl,
    this.fotoKtpPath,
    this.isLocal = false,
    this.createdAt,
    this.extraData = const {},
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'local_ref': localRef,
    'kode_pelanggan': kodePelanggan,
    'nama_toko': namaToko,
    'nama_pelanggan': namaPemilik,
    'no_hp_pribadi': noHpPribadi,
    'alamat_usaha': alamatUsaha,
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
    'foto_toko_url': fotoTokoUrl,
    'foto_ktp_path': fotoKtpPath,
    'is_local': isLocal,
    'created_at': createdAt,
    ...extraData,
  };

  String get displayName => namaToko ?? namaPemilik ?? 'Unknown';
}
