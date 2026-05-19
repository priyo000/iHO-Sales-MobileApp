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
