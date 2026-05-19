import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/promo_repository.dart';
import '../../data/promo_calculator.dart';
import '../../data/models/promo_model.dart';
import '../../data/models/cart_item_model.dart';
import 'cart_controller.dart';

// ─── Available Promos Provider (SSOT with Streams) ────────────────────────────

/// SSOT Stream provider for promos per customer.
/// Watches Drift PromoTable stream - auto-updates when data changes.
/// NO automatic sync on empty - sync is handled by PreloadService or manual refresh.
final availablePromosProvider = StreamProvider.family<AvailablePromos, String>((
  ref,
  idPelanggan,
) {
  final repo = ref.watch(promoRepositoryProvider);

  // Transform PromoTableData stream to AvailablePromos
  return repo.watchPromosForPelanggan(idPelanggan).map(
    (rows) => repo.promosFromTableData(rows),
  ).handleError((e) {
    log('[PromoController] Stream error for pelanggan $idPelanggan: $e');
    return const AvailablePromos.empty();
  });
});

/// Force refresh promos - call this for pull-to-refresh or initial load
Future<void> refreshPromos(WidgetRef ref, String idPelanggan) async {
  final repo = ref.read(promoRepositoryProvider);
  await repo.syncFromApi(idPelanggan);
  // Stream will auto-update when DB changes
}

// ─── Promo Selection State ───────────────────────────────────────────────────

/// State promo yang dipilih sales.
/// - promoPerProduk: Map(idProduk -> ItemPromoApplied) — satu promo per produk
/// - hadiahNota: list of HadiahNotaApplied — hadiah by nota (level order)
class PromoSelectionState {
  final Map<String, ItemPromoApplied> promoPerProduk;
  final List<HadiahNotaApplied> hadiahNota;

  const PromoSelectionState({
    this.promoPerProduk = const {},
    this.hadiahNota = const [],
  });

  const PromoSelectionState.empty()
    : promoPerProduk = const {},
      hadiahNota = const [];

  PromoSelectionState copyWith({
    Map<String, ItemPromoApplied>? promoPerProduk,
    List<HadiahNotaApplied>? hadiahNota,
  }) {
    return PromoSelectionState(
      promoPerProduk: promoPerProduk ?? this.promoPerProduk,
      hadiahNota: hadiahNota ?? this.hadiahNota,
    );
  }

  /// Total diskon dari semua promo per produk
  double get totalDiskon =>
      promoPerProduk.values.fold(0.0, (s, p) => s + p.diskonAmount);

  /// Total biaya hadiah (tebus) dari semua sumber
  double get totalHadiah {
    double total = 0;
    for (final p in promoPerProduk.values) {
      if (p.isHadiah) total += (p.hargaTebus ?? 0) * (p.qtyHadiah ?? 1);
    }
    for (final h in hadiahNota) {
      total += h.hargaTebus * h.qty;
    }
    return total;
  }

  /// Promo yang dipilih untuk produk tertentu
  ItemPromoApplied? promoForProduct(String idProduk) => promoPerProduk[idProduk];

  /// True jika ada promo aktif (per produk atau by nota)
  bool get hasAnyPromo => promoPerProduk.isNotEmpty || hadiahNota.isNotEmpty;

  /// Build payload promos_applied untuk API
  List<Map<String, dynamic>> buildPromosPayload() {
    final list = <Map<String, dynamic>>[];
    for (final p in promoPerProduk.values) {
      list.add(p.toPromoPayload());
    }
    for (final h in hadiahNota) {
      list.add(h.toPromoPayload());
    }
    return list;
  }

  /// Build payload hadiah_ditebus untuk API
  List<Map<String, dynamic>> buildHadiahPayload() {
    final list = <Map<String, dynamic>>[];
    for (final p in promoPerProduk.values) {
      final h = p.toHadiahPayload();
      if (h != null) list.add(h);
    }
    for (final h in hadiahNota) {
      list.add(h.toHadiahPayload());
    }
    return list;
  }

  // ─── Legacy getters (dipakai di prepareEdit restore) ─────────────────────
  SelectedPromo? get selectedPromo {
    if (promoPerProduk.isEmpty) return null;
    final first = promoPerProduk.values.first;
    return SelectedPromo(
      idCampaign: first.idCampaign,
      namaPromo: first.namaPromo,
      jenis: first.jenis,
      diskonTotal: totalDiskon,
    );
  }

  List<HadiahDitebus> get hadiahDitebus {
    final list = <HadiahDitebus>[];
    for (final p in promoPerProduk.values) {
      if (p.isHadiah && p.idProdukHadiah != null) {
        list.add(
          HadiahDitebus(
            idCampaign: p.idCampaign,
            namaPromo: p.namaPromo,
            idProdukHadiah: p.idProdukHadiah!,
            namaProdukHadiah: p.namaProdukHadiah,
            qty: p.qtyHadiah ?? 1,
            hargaTebus: p.hargaTebus ?? 0,
          ),
        );
      }
    }
    for (final h in hadiahNota) {
      list.add(
        HadiahDitebus(
          idCampaign: h.idCampaign,
          namaPromo: h.namaPromo,
          idProdukHadiah: h.idProdukHadiah,
          namaProdukHadiah: h.namaProdukHadiah,
          qty: h.qty,
          hargaTebus: h.hargaTebus,
        ),
      );
    }
    return list;
  }

  bool isHadiahSelected(String idCampaign, String idProdukHadiah) {
    return hadiahNota.any(
      (h) => h.idCampaign == idCampaign && h.idProdukHadiah == idProdukHadiah,
    );
  }
}

// ─── Promo Selection Notifier ─────────────────────────────────────────────────

final promoSelectionProvider =
    NotifierProvider<PromoSelectionNotifier, PromoSelectionState>(
      PromoSelectionNotifier.new,
    );

class PromoSelectionNotifier extends Notifier<PromoSelectionState> {
  @override
  PromoSelectionState build() => const PromoSelectionState.empty();

  /// Pilih promo untuk produk tertentu. Satu produk hanya boleh satu promo.
  /// Otomatis reset harga produk tersebut ke standar.
  void selectPromoForProduct(ItemPromoApplied promo) {
    ref
        .read(cartControllerProvider.notifier)
        .resetPriceForProduct(promo.idProduk);
    final newMap = Map<String, ItemPromoApplied>.from(state.promoPerProduk);
    newMap[promo.idProduk] = promo;
    state = state.copyWith(promoPerProduk: newMap);
  }

  /// Hapus promo untuk produk tertentu
  void clearPromoForProduct(String idProduk) {
    final newMap = Map<String, ItemPromoApplied>.from(state.promoPerProduk);
    newMap.remove(idProduk);
    state = state.copyWith(promoPerProduk: newMap);
  }

  /// Toggle hadiah by nota
  void toggleHadiahNota(HadiahNotaApplied hadiah) {
    final idx = state.hadiahNota.indexWhere(
      (h) =>
          h.idCampaign == hadiah.idCampaign &&
          h.idProdukHadiah == hadiah.idProdukHadiah,
    );
    final newList = [...state.hadiahNota];
    if (idx >= 0) {
      newList.removeAt(idx);
    } else {
      newList.add(hadiah);
    }
    state = state.copyWith(hadiahNota: newList);
  }

  /// Update diskonAmount untuk promo yang sudah dipilih (dipanggil saat qty berubah sebelum confirm)
  void updateDiskonForProduct(String idProduk, double diskonAmount) {
    final existing = state.promoPerProduk[idProduk];
    if (existing == null) return;
    final newMap = Map<String, ItemPromoApplied>.from(state.promoPerProduk);
    newMap[idProduk] = ItemPromoApplied(
      idCampaign: existing.idCampaign,
      namaPromo: existing.namaPromo,
      jenis: existing.jenis,
      idProduk: existing.idProduk,
      diskonAmount: diskonAmount,
      idProdukHadiah: existing.idProdukHadiah,
      namaProdukHadiah: existing.namaProdukHadiah,
      qtyHadiah: existing.qtyHadiah,
      hargaTebus: existing.hargaTebus,
    );
    state = state.copyWith(promoPerProduk: newMap);
  }

  /// Recalculate diskon for a product when its quantity changes in cart.
  /// Call this from CartController.updateQuantity() after cart state is updated.
  void recalculateDiskonForProduct({
    required String productId,
    required List<CartItem> allCartItems,
    required AvailablePromos promos,
  }) {
    final selected = state.promoPerProduk[productId];
    if (selected == null) return;

    double newDiskon = 0;
    if (selected.jenis == 'aturan_harga') {
      final promo = promos.aturanHarga
          .where((p) => p.idCampaign == selected.idCampaign)
          .firstOrNull;
      if (promo != null) {
        newDiskon = PromoCalculator.aturanHargaDiskonPerProduk(
            promo, allCartItems, productId);
      }
    } else if (selected.jenis == 'grosir') {
      final promo = promos.grosir
          .where((p) => p.idCampaign == selected.idCampaign)
          .firstOrNull;
      if (promo != null) {
        newDiskon = PromoCalculator.grosirDiskonPerProduk(
            promo, allCartItems, productId);
      }
    }

    updateDiskonForProduct(productId, newDiskon);
  }

  void reset() => state = const PromoSelectionState.empty();

  // ─── Legacy methods (dipakai di prepareEdit & order_review sementara) ─────

  void selectPromo(SelectedPromo promo) {
    // No-op: legacy path, tidak dipakai di flow baru
    // Dipertahankan agar prepareEdit tidak break saat restore
  }

  void toggleHadiah(HadiahDitebus hadiah) {
    // Konversi ke HadiahNotaApplied untuk backward compat restore
    toggleHadiahNota(
      HadiahNotaApplied(
        idCampaign: hadiah.idCampaign,
        namaPromo: hadiah.namaPromo,
        idProdukHadiah: hadiah.idProdukHadiah,
        namaProdukHadiah: hadiah.namaProdukHadiah,
        qty: hadiah.qty,
        hargaTebus: hadiah.hargaTebus,
      ),
    );
  }

  void clearPromo() => reset();
}

// ─── Promo Diskon Calculator (delegate ke PromoCalculator) ───────────────────

/// Helper untuk kalkulasi diskon dari UI — wraps PromoCalculator.
/// Pisah dari state agar testable dan tidak ada logic di notifier.
class PromoDiskonHelper {
  const PromoDiskonHelper._();

  static double aturanHarga(PromoAturanHarga promo, List<CartItem> items) =>
      PromoCalculator.aturanHargaDiskon(promo, items);

  static double grosir(PromoGrosir promo, List<CartItem> items) =>
      PromoCalculator.grosirDiskon(promo, items);

  static bool hadiahTerpenuhi(
    PromoHadiahItem item,
    List<CartItem> items,
    double total,
  ) => PromoCalculator.hadiahSyaratTerpenuhi(item, items, total);
}
