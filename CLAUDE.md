# iHO-now Mobile - Sales Tracker App

## Business Flow

Aplikasi mobile untuk tim sales lapangan (field salesman).

---

### 1. Planned Visit (Kunjungan Terjadwal)

Salesperson punya **jadwal harian** dari backend (`schedule_table`):
1. **Jadwal tab** (RouteSchedulePage) → daftar pelanggan yg harus dikunjungi
2. Tap kartu → **CustomerDetailPage** → Check-in (verifikasi GPS)
3. Setelah check-in → **Catalog** → pilih produk, apply promo, keranjang
4. **Checkout** `/checkout`:
   - **Dengan Order**: order tersimpan
   - **Tanpa Order**: wajib pilih alasan + foto bukti

---

### 2. Unplanned Visit (Kunjungan di Luar Jadwal)

Saat check-in ke pelanggan yang **TIDAK ada di jadwal**:
- Dari **Pelanggan List** `/customers` atau route lain (bukan dari jadwal)
- Visit disimpan dengan `scheduleId == null`
- Visit muncul di **Jadwal tab** (digabung, ditandai `id_jadwal == null`)
- Flow sama: check-in → catalog/order → checkout

---

### 3. Prospect (Identifikasi Pelanggan Baru)

Tab **Prospecting** di halaman Kunjungan (`/schedule`):

1. **QuickProspecting** `/prospecting` → input: nama toko, foto, GPS, alamat
2. Pilih aksi:
   - **Laporkan Penolakan**: simpan sebagai `prospect` (status=prospect) + alasan
   - **Daftarkan jadi Pelanggan**: registrasi lengkap via `/add-customer`

---

### 4. Customer Tagging

Setelah registrasi, tagging lokasi (`/customers/tagging`):
- Tap peta / GPS → pinpoint lokasi toko
- Reverse geocoding otomatis (Nominatim/OSM)
- Simpan koordinat + alamat (kecamatan, kota, provinsi)

---

### 5. Order Tanpa Kunjungan

Dari halaman Catalog `/products` langsung:
- Pilih pelanggan → catalog → order
- `kunjunganId = null` (tanpa visit)
- Untuk follow-up order customer existing

---

### 6. Checkout Tanpa Order

Jika check-in tapi **tdk ada order** → `/checkout`:
- Wajib pilih alasan (`Toko Tutup`, `Pemilik Tidak Ada`, `Stok Penuh`, `Lainnya`)
- Wajib upload minimal 1 foto bukti
- Visit tetap terekam dengan alasan

---

### 7. Promo

- Promo **per-customer** (backend tentukan via cluster/division)
- Jenis: `aturan_harga`, `grosir` (qty-based), `hadiah`
- Stream dari `watchPromosForPelanggan(idPelanggan)` → UI auto-update

---

## Tech Stack

- **Framework**: Flutter (Dart)
- **State**: Riverpod (StreamProvider + AsyncNotifier)
- **Local DB**: Drift (SQLite) — **SSOT**
- **Network**: Dio
- **Auth**: Token (SharedPreferences)
- **Push**: FCM
- **Navigation**: GoRouter
- **Sync**: WorkManager

## Architecture

### Drift SSOT Pattern
```
API → Repository.sync() → Drift DB → StreamProvider → UI
Write: UI → Repository → Drift DB → SyncQueue → BackgroundSync → API
```

### Key Tables (SSOT)
- `schedule_table` — jadwal harian
- `visits_table` — kunjungan (planned + unplanned, `scheduleId == null` = unplanned)
- `customers_table` — pelanggan (incl. `status=prospect`)
- `orders_table` — pesanan
- `products_table` / `categories_table` — katalog
- `promo_table` — promo per-customer (composite key: id + idPelanggan)
- `sync_queue_table` — offline mutation queue

### Sync Queue
Mutasi → Drift immediately → SyncQueue → BackgroundSync → API

---

## Architecture Standards

Konvensi kode yang berlaku project-wide. Reviewer wajib reject PR yang melanggar ini.

### Layered access path
`UI → Controller → Repository → DAO → Drift`. UI tidak panggil DAO langsung; controller tidak panggil Dio langsung; repository tidak emit Flutter widgets.

### Reactive providers (Riverpod)
- Stream dari Drift → **`StreamProvider<T>`** atau `StreamProvider.family<T, P>`. Jangan pakai `Provider<Stream<T>>` (anti-pattern: Riverpod tidak kelola lifecycle/error/loading).
- One-shot fetch → `FutureProvider<T>`.
- State yang punya actions → `AsyncNotifierProvider` / `NotifierProvider`.
- Consumer pakai `.when(data, loading, error)`. `StreamBuilder` hanya untuk stream non-Riverpod.

### Constants & enums (jangan pakai magic strings)
- Order status → [OrderStatus](mobile_refactor/lib/core/constants/order_status.dart)
- Payment system / method → [PaymentSystem, PaymentMethod](mobile_refactor/lib/core/constants/payment.dart)
- Visit / Schedule status, Checkout reason → [VisitStatus, CheckoutReason](mobile_refactor/lib/core/constants/visit_status.dart)

### Theme tokens (jangan pakai inline styles)
- Warna → [AppColors](mobile_refactor/lib/core/theme/app_colors.dart)
- Tipografi → [AppTextStyles](mobile_refactor/lib/core/theme/app_text_styles.dart)
- Spacing & radius → [AppSpacing](mobile_refactor/lib/core/theme/app_spacing.dart)

### Shared utilities (jangan reinvent)
- Format currency / date → [Formatters](mobile_refactor/lib/core/utils/formatters.dart)
- JSON → typed parsers → [json_parsers.dart](mobile_refactor/lib/core/utils/json_parsers.dart)
- Status warna / icon → [StatusStyles](mobile_refactor/lib/core/utils/status_styles.dart)
- GPS → [LocationService.getCurrentWithPermission()](mobile_refactor/lib/core/services/location_service.dart) (jangan duplikasi `Geolocator.checkPermission` boilerplate)
- Image picker → [ImagePickerService](mobile_refactor/lib/core/services/image_picker_service.dart)

### Sync queue mutations
Mutasi yang harus sampai ke server **wajib** lewat `enqueue*` helper di [SyncService](mobile_refactor/lib/core/services/sync_service.dart):
- `enqueueCheckIn`, `enqueueCheckOut`, `enqueueUpdateScheduleStatus`, `enqueueCreateOrder`, dll.
- Jangan tulis ke Drift saja kalau server perlu tahu — drift change adalah local state, queue adalah server contract.
- Jangan pakai `rawUpdate` — pakai DAO type-safe ([SyncDao](mobile_refactor/lib/core/db/daos/sync_dao.dart)).

### Repository sync contract
Setiap repository yang tarik data dari server expose `Future<void> syncFromApi({bool forceRefresh = false})` (atau alias yang konsisten). Read selalu dari Drift via `watchXxx()` stream. Jangan baca API langsung dari controller.

### Error handling
- Boundary: throw with context (wrap with descriptive message).
- Internal: trust framework guarantees, jangan defensive-code.
- Hindari `catch (_) {}` — minimal log error sebelum swallow.

### File size budget
- UI page > 500L → ekstrak sub-widgets ke `presentation/widgets/`.
- Repository > 500L → pertimbangkan split per domain concern.
- DAO > 300L → pertimbangkan split.

### Datetime / Timestamp
- **Timestamp ke server / Drift**: pakai [Formatters.nowServerIso()](mobile_refactor/lib/core/utils/formatters.dart) atau `Formatters.toServerIso(dt)`. Jangan `DateTime.now().toIso8601String()` langsung — string naive akan ditebak timezone-nya oleh server (UTC+8) → drift 1 jam saat round-trip.
- **Parsing dari server**: `DateTime.tryParse(...)?.toLocal()`. Conversion ke local time hanya di display layer (widget), bukan di repository/controller.
- **Filter Drift "today"**: pakai range query dari local day boundaries di-convert ke UTC, bukan `LIKE 'YYYY-MM-DD%'`. Contoh: [getTodayVisits](mobile_refactor/lib/core/db/daos/visit_dao.dart).

