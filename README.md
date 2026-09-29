# Roadmap Penggunaan — Sistem Distribusi Barang

Dokumen ini menjelaskan **alur kerja penggunaan aplikasi**, dari setup awal
sampai siklus kerja harian/bulanan. Beda dari `README.md` (yang isinya
catatan teknis tiap batch pengembangan untuk developer), dokumen ini
ditulis untuk **pemakai aplikasi** — pemilik bisnis, admin, dan staf
operasional — supaya paham urutan pemakaian yang benar.

---

## 1. Gambaran Umum

Aplikasi ini menggantikan sistem lama berbasis Clipper/DOS untuk bisnis
**distribusi barang** (grosir/distributor ke toko-toko, dengan barang
dari beberapa prinsipal/supplier). Alur bisnis intinya:

```
PRINSIPAL (supplier)  →  GUDANG KITA  →  TOKO (pelanggan)
      │                      │                  │
  Beli/Hutang            Simpan Stok        Jual/Piutang
```

Aplikasi berjalan di browser (Chrome/Edge/Firefox), diakses lewat jaringan
lokal kantor atau internet (tergantung cara hosting-nya). Tampilannya ada
2 pilihan tema — **Klasik** (mirip layar DOS biru-kuning, buat yang
terbiasa sistem lama) dan **Modern** (tampilan masa kini) — bisa
di-switch kapan saja lewat tombol di pojok kanan atas, tidak memengaruhi
data.

---

## 2. Peran & Level Akses

Setiap user punya **Level 1–4**. Semakin kecil angkanya, semakin besar
wewenangnya:

| Level | Sebutan | Bisa apa |
|---|---|---|
| **1** | Admin | Semua akses, termasuk Users Maintenance, Backup Data |
| **2** | Supervisor Senior | Semua Level 3 + Log Aktivitas, Notifikasi WhatsApp |
| **3** | Supervisor | Boleh **hapus** data, approve Stok Opname, override blokir limit kredit |
| **4** | Staf/Operator | Boleh **entry & ubah** data transaksi, tidak boleh hapus |

**Prinsip yang dipakai:** dari eksplorasi sistem Clipper lama, ternyata
hak akses aslinya jauh lebih granular (per-user per-layar, ~242 layar
berbeda). Kami sengaja **tidak meniru itu** — sistem 4-level ini jauh
lebih gampang dirawat untuk aplikasi yang terus berkembang seperti ini,
dan pola pemberian akses di data lama pun sebenarnya membentuk gerombolan
tingkatan (bukan benar-benar acak). Lihat README bagian batch terakhir
untuk detail pertimbangannya.

---

## 3. Setup Awal (dilakukan SEKALI sebelum mulai pakai)

Urutan ini penting — beberapa data saling bergantung.

### 3.1 Instalasi Teknis
1. Siapkan MySQL, jalankan `db/schema.sql` (struktur tabel)
2. **Kalau punya backup DBF Clipper lama**: jalankan `db/convert_dbf_to_sql.py`
   (data master) dan `db/convert_histori_harga.py` (histori harga/HPP,
   opsional tapi disarankan — bikin Laporan Laba Kotor jauh lebih akurat)
3. Copy `.env.example` jadi `.env`, isi koneksi database
4. `npm install`, lalu `node server.js`
5. Buka browser ke alamat servernya — kalau belum ada user sama sekali,
   otomatis diarahkan ke halaman **Setup** untuk buat akun Admin pertama

### 3.2 Isi Data Referensi (Master → submenu "Referensi")
Isi berurutan (yang belakangan sering butuh yang sebelumnya sebagai
pilihan dropdown):
1. **Gudang** — minimal 1 gudang aktif
2. **Group Barang**, **Divisi**, **Satuan** — pengelompokan barang
3. **Prinsipal** — daftar supplier/prinsipal
4. **Jenis Toko**, **Segment Toko**, **Daerah/Area** — pengelompokan toko

### 3.3 Isi Data Master Inti
1. **Master → Barang** — daftarkan barang, isi `stok_minimum` kalau mau
   dipakai fitur peringatan Stok Kritis di Beranda. Ada juga
   **Import/Export Excel** buat update harga banyak barang sekaligus
   (lihat bagian 10). Kalau barang tertentu punya 3 tingkat satuan (mis.
   Karton → Lusin → Pcs, bukan cuma Karton → Pcs), isi **Satuan Sedang**
   di halaman edit barang itu (opsional, boleh dikosongkan kalau cuma
   2 tingkat seperti biasa).
2. **Master → Toko** — daftarkan toko pelanggan, isi **No. HP/WhatsApp**
   kalau mau pakai reminder tagihan otomatis, isi **Plafon Nota** &
   **Plafon Kredit** kalau mau pakai fitur blokir limit kredit. Kalau
   jumlah tokonya banyak, pakai **Import/Export Excel** di halaman
   Master Toko (unduh template, isi/edit di Excel, upload lagi) daripada
   input satu-satu — kode toko yang sudah ada otomatis di-update, kode
   baru otomatis ditambahkan.
3. **Master → Salesman** — daftarkan salesman
4. **Barang → Harga 3 Level** (di halaman edit tiap barang) — set harga
   jual T.O / Kanvas / Motoris per barang
5. **Barang → Barcode** (opsional) — daftarkan barcode kemasan
   karton & pcs kalau gudang pakai scanner

### 3.4 Users & Hak Akses
1. **Utility → Users Maintenance** — buat akun untuk tiap staf, tentukan
   Level 1–4 sesuai peran (lihat tabel di bagian 2)
2. **Utility → Profil Perusahaan** — isi data perusahaan (nama, alamat,
   NPWP, dll, dipakai di kop cetakan Nota/Faktur Pajak), termasuk
   **Tarif PPN** yang berlaku saat ini (default 11%, bisa diedit kalau
   aturan pajak berubah di kemudian hari — lihat catatan penting di
   bagian 13 soal ini)
3. **Utility → Notifikasi WhatsApp** (opsional) — isi `.env`
   (`API_URL_WA`, `WA_NOMOR_OWNER`, dll), set `WA_NOTIFIKASI_AKTIF=true`
   kalau gateway WA sudah siap, lalu kirim 1 pesan tes dari halaman ini.
   Halaman ini juga jadi tempat **cek riwayat notifikasi yang sudah
   terkirim** (log lengkap dengan filter tanggal & jenis pesan) dan
   **tombol jalankan manual** untuk 3 tugas otomatisnya (Rekap Harian,
   Reminder Jatuh Tempo, Alert Stok Kritis) — berguna kalau mau
   memicunya di luar jam terjadwal, atau kalau ternyata terlewat pas
   servernya sempat mati pas jamnya.

### 3.5 Saldo Awal (kalau migrasi dari sistem lama)
- **Gudang → Nota Kredit Awal** — masukkan saldo piutang/CN toko yang
  masih outstanding dari sistem lama, supaya Laporan Piutang & Monitoring
  Tagihan langsung akurat sejak hari pertama pakai sistem baru
- Stok awal per barang per gudang bisa dimasukkan lewat **Stok Opname**
  (buat opname pertama, isi Qty Fisik sesuai stok riil gudang)

---

## 4. Alur Kerja Harian — Order sampai Bayar (Order-to-Cash)

Ini alur paling sering dipakai sehari-hari.

```
Toko pesan barang
      ↓
[Transaksi → Pesanan dari Toko]   ← opsional, kalau pesanan formal (PO)
      ↓
[Transaksi → Nota Penjualan]      ← WAJIB, ini yang bikin piutang & keluar stok
      ↓ (kalau ada limit kredit/plafon terlampaui → perlu approval Supervisor)
      ↓
Barang dikirim, Nota dicetak (PDF)
      ↓
[Piutang → Pembayaran]            ← saat toko bayar (tunai/transfer/giro)
      ↓
Piutang lunas, otomatis hilang dari Monitoring Tagihan & blokir kredit
```

**Detail tiap langkah:**

- **Pesanan dari Toko** *(opsional tapi disarankan untuk pesanan besar)* —
  catat dulu apa yang dipesan toko. Nota Penjualan nanti bisa
  disambungkan ke pesanan ini lewat kolom "No. Pesanan (PO)" — sistem
  otomatis tahu berapa yang sudah terkirim vs sisa, dan pesanan boleh
  dipenuhi bertahap lewat beberapa Nota.
- **Nota Penjualan** — inti dari penjualan. Pilih Toko, tambah baris
  barang (bisa **scan barcode**, bisa pilih satuan Karton/Pcs, harga
  otomatis terisi sesuai Level Harga toko itu). Begitu toko dipilih,
  sistem otomatis cek apakah toko ini **diblokir** (piutang overdue atau
  lewat plafon kredit) — kalau diblokir, cuma Supervisor (Level ≤3) yang
  bisa override dengan centang konfirmasi (tercatat ke Log Aktivitas).
  Kalau ada barang bonus, dicatat terpisah supaya tidak kena PPN, dan
  otomatis ikut mengurangi stok gudang.
- **Cetak Nota/Faktur Pajak** — tombol cetak PDF ada di halaman Nota.
- **Pembayaran** — dicatat di menu Piutang, bisa cicil/sebagian. Begitu
  lunas, otomatis tidak muncul lagi di Monitoring Tagihan.

---

## 5. Alur Kerja — Import Massal dari Matrix (SFA)

Kalau tim sales lapangan pakai **Matrix** (aplikasi Sales Force
Automation pihak ketiga) untuk mencatat kunjungan & transaksi langsung
dari HP/tablet, fitur ini menyambungkan otomatis data dari Matrix ke
sistem distribusi ini — jadi **tidak perlu input ulang manual** satu
per satu dari laporan Matrix.

### 5.1 Apa yang terjadi kalau fitur ini dipakai

Sistem membaca 1 file laporan dari Matrix (isinya bisa ribuan baris
transaksi), mengelompokkan per faktur, lalu **otomatis membuat Nota
Penjualan dan/atau Retur Toko** — lengkap dengan barang, qty, harga,
dan diskonnya — persis seperti kalau diinput manual lewat form biasa.

### 5.2 Persiapan SEKALI DI AWAL (sebelum pertama kali import)

Urutan ini penting, dan cuma perlu dilakukan sekali (kecuali ada toko
atau barang baru dari Matrix yang belum terdaftar):

1. **Master Toko harus sudah lengkap** — kode toko yang dipakai HARUS
   SAMA dengan "No Outlet" di Matrix. Cara tercepat: export data toko
   dari Matrix ke Excel, sesuaikan formatnya seperti template Master
   Toko kita (lihat bagian 3.3), lalu upload lewat **Master → Toko →
   Import/Export Excel**.
2. **Pemetaan Barang Matrix** — kode barang di Matrix beda penomoran
   dari kode barang kita, jadi perlu "kamus penerjemah" dulu. Buka
   **Utility → Import dari Matrix → Pemetaan Barang Matrix**, lalu
   daftarkan tiap kode barang Matrix (Pcode) ke kode barang kita yang
   sesuai. Barang yang belum dipetakan akan GAGAL diimpor (cuma baris
   itu yang gagal, bukan seluruh transaksinya batal) — sistem akan
   kasih tahu persis kode mana yang belum dipetakan.
3. **Salesman TIDAK perlu disiapkan manual** — kalau kode salesman dari
   Matrix belum terdaftar di Master Salesman, sistem otomatis
   membuatkan (nanti tinggal lengkapi datanya kalau perlu, mis. alamat).

### 5.3 Cara Import (rutin, tiap ada laporan baru dari Matrix)

1. Minta/export file laporan transaksi dari Matrix (format `.txt`)
2. Buka **Utility → Import dari Matrix**
3. Upload file-nya, lalu pilih:
   - **Gudang Tujuan** — gudang mana yang stoknya dikurangi/ditambah
     akibat transaksi-transaksi ini (berlaku juga untuk retur R1/lihat
     poin di bawah)
   - **Gudang Retur Expired (R2)** — gudang khusus untuk retur toko yang
     kondisi barangnya sudah expired, terpisah dari gudang biasa. Sudah
     ada isian bawaan "EXP" (gudang "RETUR EXPIRED (R2)"), bisa diganti
     kalau mau pakai gudang lain. Hanya dipakai kalau di file memang ada
     retur kondisi expired.
   - **Satuan Qty di File** — defaultnya "Satuan Kecil/Pcs" (sudah
     dikonfirmasi ke tim Matrix bahwa ini yang benar), ganti ke
     "Satuan Besar/Karton" hanya kalau ternyata ada file dengan format beda
4. Klik **Import**, tunggu prosesnya selesai
5. Cek hasilnya:
   - **Berhasil** — jumlah Nota/Retur yang berhasil dibuat, termasuk
     rincian berapa retur kondisi bagus (R1) dan berapa expired (R2)
   - **Dilewati** — transaksi yang SUDAH PERNAH diimpor sebelumnya
     (sistem otomatis mendeteksi ini, jadi upload file yang sama 2x
     TIDAK akan bikin data dobel)
   - **Gagal** — transaksi yang belum bisa diimpor, beserta alasannya
     per baris (paling sering: toko belum ada di Master Toko, atau
     barang belum dipetakan) — perbaiki penyebabnya, lalu upload ulang
     file yang sama (yang sudah berhasil otomatis dilewati, cuma yang
     gagal kemarin yang akan diproses ulang)
   - **Peringatan** — baris yang tetap berhasil diimpor tapi ada yang
     janggal (lihat poin XQTYPCS di bawah), untuk dicek ulang datanya

### 5.4 Yang perlu diketahui (supaya tidak salah paham)

- Nota/Retur hasil import bisa dibuka & diedit seperti Nota biasa kalau
  memang perlu dikoreksi manual
- Cek limit kredit/plafon toko **tidak berlaku** untuk transaksi hasil
  import (karena ini transaksi yang sudah benar-benar terjadi di masa
  lalu, bukan keputusan kredit baru yang perlu di-approve)
- **Retur otomatis dipecah jadi 2 dokumen kalau isinya campuran** —
  field "KG" di data Matrix menandai kondisi barang retur (R1 = masih
  bagus, R2 = sudah expired). Kalau 1 faktur retur dari Matrix berisi
  campuran R1 dan R2, sistem membuat **2 dokumen Retur Toko terpisah**:
  yang R1 masuk Gudang Tujuan biasa (bisa dijual lagi), yang R2 masuk
  Gudang Retur Expired (tidak tercampur dengan stok layak jual). Kalau
  ada baris retur yang kondisinya tidak jelas di data Matrix, sistem
  menganggapnya R1 dan memberi peringatan supaya dicek manual.
- **QTYPCS** (qty di file) sudah dipastikan dalam satuan Pcs (satuan
  terkecil), dan **XQTYPCS** (rincian qty asli per satuan besar/tengah/
  kecil) dipakai untuk **mengecek ulang** apakah qty di file sudah sesuai
  dengan isi Karton/Sedang yang terdaftar di Master Barang. Kalau tidak
  cocok, transaksinya **tetap berhasil diimpor**, tapi barisnya muncul di
  daftar Peringatan supaya bisa dicek — biasanya tandanya isi per Karton
  di Master Barang belum benar

---

## 5b. Alur Kerja — Import Analisa Pembelian dari Matrix

**Beda dengan bagian 5 di atas** — ini modul terpisah, bukan bagian dari
alur import transaksi penjualan SFA. **Pembelian Matrix** dipakai untuk
mengimpor laporan pembelian/margin dari file Excel "Matrix" (laporan
analisa pembelian per prinsipal, bukan file transaksi kunjungan sales),
untuk keperluan rekap margin & disc allowance per barang serta ekspor ke
tim akunting.

Ringkas alurnya:
1. **Utility → Pembelian Matrix → Pemetaan Suplier** — petakan dulu kode
   suplier di file Matrix ke kode Prinsipal kita (sekali di awal, sama
   prinsipnya dengan Pemetaan Barang Matrix di bagian 5.2)
2. **Utility → Pembelian Matrix → Import** — upload file Excel (`.xlsx`)
   laporannya
3. Hasil impor tersimpan sebagai dokumen tersendiri (bisa dilihat
   detailnya, dihapus kalau salah upload)
4. **Export** — unduh rekapnya dalam format Excel untuk dikirim ke
   bagian akunting/jurnal

Field **Margin Matrix (%)** dan **Disc. Allowance Matrix (%)** ikut
ditambahkan di halaman edit Master Barang untuk keperluan modul ini.

Level akses: Level ≤3 (Supervisor ke atas) untuk Import & kelola
Pemetaan Suplier. Panduan detail step-by-step (dengan contoh tangkapan
layar) ada di dokumen terpisah Download => **"[Panduan Pemakaian Pembelian Matrix](Panduan-Pemakaian-Pembelian-Matrix.docx)"**.

---

## 6. Alur Kerja — Pengadaan Barang (Procure-to-Stock)

```
Butuh restok barang dari prinsipal
      ↓
[Gudang → Surat Pesanan (PO)]     ← order ke prinsipal (opsional, lihat catatan di bawah)
      ↓
Barang datang dari prinsipal
      ↓
[Gudang → Penerimaan Barang]      ← catat barang masuk, PO opsional
      ↓
Stok otomatis bertambah di Kartu Stok, Hutang ke Prinsipal otomatis tercatat
      ↓
[Hutang → Pembayaran]             ← saat kita bayar ke prinsipal (lihat bagian 6.2)
```

### 6.1 Penerimaan Barang — dengan atau tanpa Surat Pesanan

**No. Pesanan di form Penerimaan Barang sifatnya OPSIONAL** (per update
terbaru — sebelumnya wajib, sekarang dilonggarkan supaya sesuai kondisi
lapangan yang sebenarnya):

- **Kalau diisi** — sistem mencocokkan ke Surat Pesanan yang sudah dibuat,
  Prinsipal otomatis terisi dari PO tsb (tidak bisa dipilih manual, supaya
  tidak mungkin beda dari prinsipal aslinya), dan barang yang diterima
  harus ada di baris PO itu.
- **Kalau dikosongkan** — dipakai untuk barang yang datang **tanpa PO
  didahului** (mis. kiriman konsinyasi/titipan dari prinsipal, barang
  sample, atau PO baru dibuatkan belakangan setelah barang fisik tiba).
  Dalam kondisi ini, **Prinsipal wajib dipilih manual** lewat field
  pencarian yang muncul di form, dan kode barang yang diinput tetap
  divalidasi ke Master Barang (tapi tidak perlu cocok ke baris PO
  manapun, karena memang tidak ada PO-nya).

Pilih mana yang dipakai sesuai kondisi riil: kalau memang ada Surat
Pesanan yang mendahului, tetap isi No. Pesanan-nya (lebih tertelusur).
Kosongkan hanya kalau barangnya benar sudah datang duluan.

### 6.2 Hutang ke Prinsipal & Pembayarannya

Tiap **Penerimaan Barang** yang tersimpan otomatis jadi catatan hutang ke
prinsipal terkait (nilainya dihitung dari qty × harga tiap baris barangnya)
— polanya sama persis dengan Piutang toko di bagian 8, cuma arahnya
kebalik (kita yang berhutang & yang bayar, bukan yang ditagih):

- **Hutang → Pembayaran** — catat pembayaran ke prinsipal, cari nomor
  Penerimaan Barang yang masih ada sisa hutangnya (datalist pencarian
  otomatis cuma menampilkan yang belum lunas), isi nilai bayar (boleh
  cicil/sebagian, sistem cegah bayar lebih dari sisa hutangnya), pilih
  jenis bayar (Cash/Transfer atau Giro — kalau Giro, isi No. Giro & Tgl
  Jatuh Tempo Giro-nya).
- Saldo hutang per Penerimaan Barang dihitung **langsung (live)** setiap
  kali dibutuhkan, bukan disimpan di kolom terpisah — jadi selalu akurat
  meski ada perubahan baris barang setelahnya.
- Level akses: Staf (Level 4) boleh catat pembayaran, Supervisor
  (Level ≤3) yang boleh menghapusnya.
- Belum ada mekanisme "Retur ke Prinsipal otomatis mengurangi hutang" —
  kalau retur perlu mengurangi hutang yang belum dibayar, catat manual
  dulu sebagai pengurang lewat pembayaran jenis Cash/Transfer biasa.
- Lihat progress-nya di **Laporan → Umur Hutang** (aging per prinsipal,
  mirip Umur Piutang) dan **Laporan → Pembayaran Hutang** (rekap yang
  sudah dibayar per periode).

---

## 7. Alur Kerja — Manajemen Gudang & Stok

Dipakai berkala (mingguan/bulanan), bukan tiap hari:

- **Pengambilan/Transfer** — pindah stok antar gudang (kalau ada lebih
  dari 1 gudang)
- **Retur Toko / CN** — toko mengembalikan barang, otomatis jadi Nota
  Kredit (CN) yang mengurangi piutang toko itu. Ada isian **Kondisi
  Retur** (R1 = masih bagus, R2 = expired) yang menentukan barangnya
  masuk gudang mana — tampil juga di daftar Retur Toko dan Laporan Retur.
  Untuk retur manual (bukan dari import Matrix), isian ini opsional.
  Kalau Retur ditautkan ke
  Nomor Nota Penjualan aslinya (field "Nomor Nota Asli"), dan Nota
  aslinya ada diskon, harga & diskon di baris Retur bisa **otomatis
  ke-isi sama persis** dengan Nota asli begitu barangnya dipilih (tetap
  bisa diubah manual kalau memang mau beda) — supaya nilai kredit yang
  diberikan konsisten dengan yang benar-benar pernah dijual.
- **Retur ke Prinsipal** — barang dikembalikan ke prinsipal (rusak/mati)
- **Stok Opname** — hitung fisik stok gudang, dibandingkan ke sistem.
  Alur approval 2 tahap: **DRAFT** (bebas diedit, belum sentuh Kartu
  Stok) → **Finalisasi** (Level ≤3, baru saat ini selisihnya tercatat
  permanen). Bisa isi manual satu-satu, scan barcode, atau **import
  massal lewat Excel** (unduh template, isi di Excel, upload lagi) —
  cocok untuk hitung stok gudang penuh.
- **Kartu Stok** (di menu Saldo Stok) — lihat riwayat keluar-masuk tiap
  barang per gudang, sumber kebenaran (source of truth) untuk semua
  angka stok di aplikasi ini.

---

## 8. Alur Kerja — Penagihan & Manajemen Kredit

Ini area yang paling berhubungan dengan arus kas bisnis:

1. **Beranda** — sekilas pandang tiap login: Omzet Hari Ini/Bulan Ini,
   Piutang Overdue, Stok Kritis, Top 5 Toko
2. **Laporan → Monitoring Tagihan** — daftar per-nota yang jatuh tempo
   hari ini / sudah lewat tempo, dengan filter Toko/Salesman
3. **Notifikasi WhatsApp otomatis** (kalau diaktifkan) — tiap hari jam
   yang diatur di `.env`:
   - Reminder ke toko yang overdue (otomatis, ke No. HP di Master Toko)
   - Rekap penjualan harian ke Owner
   - Alert stok kritis ke bagian Pembelian
4. **Blokir otomatis** — toko yang overdue atau lewat plafon kredit tidak
   bisa dibuatkan Nota baru **kecuali** di-override Supervisor. Ini
   mencegah piutang toko yang sudah bermasalah terus membengkak tanpa
   sepengetahuan atasan.

---

## 9. Alur Kerja — Laporan & Analisa

Semua di menu **Laporan**:

| Laporan | Kegunaan |
|---|---|
| Laporan Penjualan | Rekap jual per toko/salesman/barang |
| Laba Kotor | Margin per Barang/Toko/Salesman/Prinsipal — pakai histori HPP asli kalau tersedia |
| Rugi Laba Sederhana | Laba Kotor dikurangi Biaya Operasional (bukan pembukuan resmi) |
| Umur Piutang | Aging piutang per toko (bucket 0-30/31-60/61-90/90+ hari) |
| Monitoring Tagihan | Detail per-nota jatuh tempo (lihat bagian 8) |
| Pembayaran Piutang | Rekap pembayaran yang sudah diterima dari toko per periode |
| Umur Hutang | Aging hutang ke prinsipal per Penerimaan Barang (bucket sama seperti Umur Piutang, lihat bagian 6.2) |
| Pembayaran Hutang | Rekap pembayaran yang sudah dilakukan ke prinsipal per periode |
| Laporan Pembelian | Rekap Penerimaan Barang per Prinsipal/Barang (bisa pilih pengelompokannya) |
| Laporan Stok | Posisi stok per barang per gudang |
| Laporan Retur | Rekap retur toko & retur prinsipal, termasuk rekap per Kondisi Retur (bagus/expired) |
| Analisa Budget Barang | Realisasi vs target budget per barang |
| Analisa Penjualan Salesman | Kinerja tiap salesman |
| Deviasi Omzet | Salesman dengan pola retur mencurigakan |
| Ekspor Data Pajak | Siapkan data buat pelaporan Coretax (bukan file impor resmi, cuma bantu susun) |

---

## 10. Alur Kerja — Admin & Utility (berkala)

- **Biaya Operasional** — catat pengeluaran rutin (gaji, sewa, dll),
  jadi pengurang di Laporan Rugi Laba Sederhana
- **Backup Data** *(Admin only)* — unduh backup `.sql` sebelum operasi
  berisiko (import massal, dll). **Lakukan rutin**, simpan di tempat
  terpisah dari server
- **Log Aktivitas** *(Level ≤2)* — audit siapa login/simpan/hapus apa,
  termasuk override limit kredit
- **Riwayat Perubahan Harga** (di halaman edit tiap Barang) — jejak
  siapa mengubah harga, kapan, dari berapa ke berapa
- **Import/Export Excel Massal** — update harga banyak barang sekaligus
  (Master Barang → Import/Export Harga), atau update data toko massal
  (Master Toko → Import/Export Excel)
- **Import dari Matrix** *(Level ≤3)* — lihat bagian 5 utk panduan
  lengkap. Halaman **Pemetaan Barang Matrix** (kelola kode barang
  Matrix ↔ kode barang kita) juga ada di menu ini.

---

## 11. Ringkasan Siklus Waktu

| Frekuensi | Aktivitas |
|---|---|
| **Tiap transaksi** | Nota Penjualan, Pembayaran (Piutang), Penerimaan Barang |
| **Harian** | Cek Beranda, proses Pesanan dari Toko baru, notifikasi WA otomatis jalan sendiri, import laporan Matrix (kalau tim sales pakai Matrix & laporannya harian) |
| **Mingguan** | Pengambilan/Transfer antar gudang (kalau perlu), review Monitoring Tagihan, bayar Hutang ke Prinsipal yang jatuh tempo, import Matrix (kalau laporannya mingguan) |
| **Bulanan** | Stok Opname per gudang, Laporan Laba Kotor & Rugi Laba, catat Biaya Operasional, cek Laporan Umur Hutang |
| **Sebelum operasi berisiko** | Backup Data manual |
| **Sesekali/insidental** | Retur Toko/Prinsipal, Nota Kredit Awal (cuma saat migrasi), Import Pembelian Matrix (kalau ada laporan baru dari prinsipal) |

---

## 12. Peta Menu Lengkap

```
Beranda                          (dashboard KPI)

Master
 ├─ Barang, Toko, Salesman
 ├─ Budget Barang, Target Salesman
 └─ Referensi: Group Barang, Divisi, Jenis Toko, Segment Toko,
               Daerah/Area, Satuan, Gudang, Prinsipal

Transaksi
 ├─ Nota Penjualan
 └─ Pesanan dari Toko

Piutang
 └─ Pembayaran

Hutang
 └─ Pembayaran (ke Prinsipal — lihat bagian 6.2)

Gudang
 ├─ Saldo Stok (Kartu Stok)
 ├─ Surat Pesanan (PO ke Prinsipal)
 ├─ Penerimaan Barang           (No. Pesanan opsional, lihat bagian 6.1)
 ├─ Pengambilan / Transfer
 ├─ Retur Toko / CN
 ├─ Retur ke Prinsipal
 ├─ Nota Kredit Awal
 └─ Stok Opname

Laporan
 └─ (lihat tabel bagian 9)

Utility
 ├─ Profil Perusahaan          (termasuk Tarif PPN)
 ├─ Users Maintenance          (Level 1)
 ├─ Biaya Operasional
 ├─ Backup Data                (Level 1)
 ├─ Log Aktivitas              (Level ≤2)
 ├─ Notifikasi WhatsApp        (Level ≤2, termasuk log riwayat & jalankan manual)
 ├─ Import dari Matrix         (Level ≤3, termasuk Pemetaan Barang Matrix)
 └─ Pembelian Matrix           (Level ≤3, lihat bagian 5b — fitur terpisah dari Import dari Matrix di atas)
```

---

## 13. Batasan yang Perlu Diketahui

Ringkas — detail lengkap tiap poin ada di `README.md`:

- **Bukan aplikasi akuntansi resmi** — tidak ada jurnal/neraca/buku besar
  berpasangan. Rugi Laba Sederhana cuma Laba Kotor dikurangi Biaya
  Operasional manual, untuk laporan resmi tetap perlu akuntan
- **Ekspor Pajak** cuma bantu susun data, bukan file impor resmi Coretax
- **Hak akses** 4-level (bukan granular per-layar seperti sistem lama) —
  keputusan sadar, lihat bagian 2
- **Laba Kotor** akurasinya tergantung cakupan histori HPP yang
  ter-import — ditampilkan transparan persentase cakupannya di halaman
  laporan itu sendiri
- **Restore backup** sengaja tidak ada tombolnya di web (terlalu
  berisiko) — lewat command line manual, lihat halaman Backup Data
- **Tarif PPN** yang berlaku dikunci per Nota saat Nota itu pertama
  dibuat — kalau tarif default diubah di kemudian hari (mis. aturan
  pajak berubah), Nota-nota LAMA tidak ikut berubah, tetap konsisten
  dengan tarif yang berlaku waktu Nota itu dibuat
- **Import dari Matrix**: field "KG" (kondisi retur R1/R2) dan "XQTYPCS"
  (validasi silang qty) sudah dipakai — lihat bagian 5.4. Satuan qty
  (Karton atau Pcs) di file Matrix tetap perlu dipilih manual tiap kali
  import (satu pilihan berlaku untuk seluruh file yang diupload), dan
  hanya perlu diganti kalau ada file dengan format tidak biasa
- **Barang bonus tidak dicek ketersediaan stoknya** — sama seperti baris
  Nota biasa, sistem tidak menolak input bonus/penjualan meski stok
  gudang sudah tidak cukup (belum ada validasi stok minus)
- Semua penyederhanaan lain didokumentasikan di `README.md` per fitur,
  dengan alasan kenapa dan cara memperluasnya kalau suatu saat dibutuhkan

---

*Dokumen ini dibuat berdasarkan kondisi aplikasi saat ini (60+ batch
pengembangan, terakhir diupdate setelah fitur: field KG (Kondisi Retur
R1/R2) & XQTYPCS di Import Matrix diterapkan, dan Barang Bonus di Nota
Penjualan sekarang tercetak di Nota dan otomatis mengurangi stok gudang).
Kalau ada modul baru ditambahkan, roadmap ini perlu di-update mengikuti.*
