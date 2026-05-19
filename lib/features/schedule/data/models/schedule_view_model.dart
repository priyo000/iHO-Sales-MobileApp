import '../../../orders/data/models/order_view_model.dart';

class ScheduleViewModel {
  final String id;
  final String? pelangganId;
  final CustomerSummary? pelanggan;
  final String tanggal;
  final String status;
  final int urutan;
  final String? visitId;
  final String? visitStatus;
  final String? waktuCheckIn;
  final String? waktuCheckOut;
  final bool hasOrder;
  final double? orderTotal;

  const ScheduleViewModel({
    required this.id,
    this.pelangganId,
    this.pelanggan,
    required this.tanggal,
    required this.status,
    this.urutan = 0,
    this.visitId,
    this.visitStatus,
    this.waktuCheckIn,
    this.waktuCheckOut,
    this.hasOrder = false,
    this.orderTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_pelanggan': pelangganId,
      'pelanggan': pelanggan != null
          ? {
              'id': pelanggan!.id,
              'nama_toko': pelanggan!.namaToko,
              'nama_pemilik': pelanggan!.namaPemilik,
              'foto_toko_url': pelanggan!.fotoTokoUrl,
              'alamat': pelanggan!.alamat,
            }
          : null,
      'tanggal': tanggal,
      'status': status,
      'urutan': urutan,
      'visit_id': visitId,
      'visit_status': visitStatus,
      'waktu_check_in': waktuCheckIn,
      'waktu_check_out': waktuCheckOut,
      'has_order': hasOrder,
      'order_total': orderTotal,
    };
  }
}
