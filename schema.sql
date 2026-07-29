-- =====================================================================
-- SCHEMA MIGRASI DARI CLIPPER (DBF) KE MYSQL 5.7
-- Sumber asli: SOURCE/AGE350.PRG, AGCOMMON.PRG (module Penjualan/Faktur)
-- Setiap kolom dikomentari dengan nama field DBF aslinya untuk
-- memudahkan cross-check ke program Clipper lama saat migrasi modul lain.
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- AgCtl -> ag_ctl : tabel kontrol / nomor urut otomatis (dulu 1 baris saja)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_ctl (
  id            TINYINT UNSIGNED NOT NULL DEFAULT 1,
  prefix_nota   VARCHAR(3)  NOT NULL DEFAULT ''   COMMENT 'PreNK_Ctl',
  prefix_cn     VARCHAR(3)  NOT NULL DEFAULT 'CN' COMMENT 'PreCN_Ctl - prefix nomor Retur/Credit Note, TERPISAH dari prefix_nota (dulu sempat kegabung, sudah dipisah lagi di batch ini)',
  no_fkt_terakhir INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'NoFkt_Ctl - counter nomor faktur',
  no_srj_terakhir INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'NoSrj_Ctl - counter nomor surat jalan',
  periode_aktif DATE NULL                          COMMENT 'Prd_Ctl - batas tanggal transaksi (locking periode)',
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO ag_ctl (id, prefix_nota, prefix_cn, no_fkt_terakhir, no_srj_terakhir)
VALUES (1, '', 'CN', 0, 0)
ON DUPLICATE KEY UPDATE id = id;

-- ---------------------------------------------------------------------
-- AgTbUnit -> ag_unit : master satuan barang
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_unit (
  kode_unit   VARCHAR(6)  NOT NULL COMMENT 'Nomor_Unit',
  nama_unit   VARCHAR(15) NOT NULL COMMENT 'Nama_Unit',
  PRIMARY KEY (kode_unit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTbGudG -> ag_gudang : master gudang
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_gudang (
  kode_gudang VARCHAR(6)  NOT NULL COMMENT 'Nomor_Gudg',
  nama_gudang VARCHAR(30) NOT NULL COMMENT 'Nama_Gudg',
  PRIMARY KEY (kode_gudang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgMsPrin -> ag_principal : master principal / prinsipal barang
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_principal (
  kode_principal VARCHAR(6)  NOT NULL COMMENT 'Nomor_Prin',
  nama_principal VARCHAR(30) NOT NULL COMMENT 'Nama_Prin',
  kode_gudang    VARCHAR(6)  NULL     COMMENT 'Gudg_Prin - gudang default',
  PRIMARY KEY (kode_principal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgMsArea -> ag_area : master wilayah/daerah toko
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_area (
  kode_area VARCHAR(6)  NOT NULL COMMENT 'Nomor_Area',
  nama_area VARCHAR(30) NOT NULL COMMENT 'Nama_Area',
  PRIMARY KEY (kode_area)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgMsSman -> ag_salesman : master salesman
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_salesman (
  kode_sman     VARCHAR(6)  NOT NULL COMMENT 'Nomor_Sman',
  nama_sman     VARCHAR(30) NOT NULL COMMENT 'Nama_Sman',
  alamat1       VARCHAR(40) NULL     COMMENT 'Almt1_Sman',
  alamat2       VARCHAR(40) NULL     COMMENT 'Almt2_Sman',
  no_ktp        VARCHAR(20) NULL     COMMENT 'KTP_Sman',
  no_sim        VARCHAR(20) NULL     COMMENT 'SIM_Sman',
  kode_gudang   VARCHAR(6)  NULL     COMMENT 'GudG_Sman - gudang asal',
  kode_principal VARCHAR(6) NULL     COMMENT 'Prin_Sman',
  target_jual   DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Jual_Sman',
  PRIMARY KEY (kode_sman)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTbGrst -> ag_group_barang : master group/kategori barang
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_group_barang (
  kode_group  VARCHAR(5)  NOT NULL COMMENT 'Nomor_Grst',
  nama_group  VARCHAR(30) NOT NULL COMMENT 'Nama_Grst',
  PRIMARY KEY (kode_group)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTbDivi -> ag_divisi : master divisi barang
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_divisi (
  kode_divisi VARCHAR(3)  NOT NULL COMMENT 'Nomor_Divi',
  nama_divisi VARCHAR(20) NOT NULL COMMENT 'Nama_Divi',
  PRIMARY KEY (kode_divisi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTbJnTk -> ag_jenis_toko : master jenis toko/outlet
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_jenis_toko (
  kode_jenis  VARCHAR(2)  NOT NULL COMMENT 'Nomor_JnTk',
  nama_jenis  VARCHAR(30) NOT NULL COMMENT 'Nama_JnTk',
  PRIMARY KEY (kode_jenis)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTbSeTK -> ag_segment_toko : master segment toko
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_segment_toko (
  kode_segment VARCHAR(6)  NOT NULL COMMENT 'Nomor_SeTk',
  nama_segment VARCHAR(30) NOT NULL COMMENT 'Nama_SeTk',
  PRIMARY KEY (kode_segment)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgMsToko -> ag_toko : master toko / pelanggan
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_toko (
  kode_toko       VARCHAR(6)  NOT NULL COMMENT 'Nomor_Toko',
  nama_toko       VARCHAR(25) NOT NULL COMMENT 'Nama_Tok',
  pemilik         VARCHAR(25) NULL     COMMENT 'Milik_Tok',
  alamat1         VARCHAR(30) NULL     COMMENT 'Almt1_Tok',
  alamat2         VARCHAR(30) NULL     COMMENT 'Almt2_Tok',
  kode_jenis      VARCHAR(2)  NULL     COMMENT 'Jenis_Tok -> ag_jenis_toko',
  nota_putih_dibatasi TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Btshr_Tok (Y/T)',
  kode_area       VARCHAR(6)  NULL     COMMENT 'Area_Tok -> ag_area',
  kode_segment    VARCHAR(6)  NULL     COMMENT 'SeTk_Tok -> ag_segment_toko',
  npwp            VARCHAR(20) NULL     COMMENT 'NPWP_Tok',
  nama_faktur     VARCHAR(50) NULL     COMMENT 'NamaX_Tok',
  alamat_faktur1  VARCHAR(60) NULL     COMMENT 'Alax_Tok',
  alamat_faktur2  VARCHAR(60) NULL     COMMENT 'Alax2_Tok',
  plafon_nota     DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'PlfNt_Tok - plafon per nota/sales',
  plafon_kredit   DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Plfn_Tok',
  saldo_piutang   DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Pihut_Tok - saldo berjalan, diupdate sistem',
  tanpa_diskon1   TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'NDsc1_Tok (Y/T)',
  grup_harga      VARCHAR(3)  NULL     COMMENT 'GrHrg_Toko - dipakai cari tabel diskon di modul Penjualan',
  no_hp           VARCHAR(20) NULL     COMMENT 'Baru -- tidak ada di Clipper asli. Nomor WhatsApp toko, dipakai reminder jatuh tempo otomatis (lihat modules/notifikasi). Format bebas asal diawali 62/0, dirapikan otomatis saat kirim.',
  PRIMARY KEY (kode_toko),
  KEY idx_area (kode_area),
  KEY idx_jenis (kode_jenis),
  KEY idx_segment (kode_segment),
  CONSTRAINT fk_toko_area FOREIGN KEY (kode_area) REFERENCES ag_area(kode_area),
  CONSTRAINT fk_toko_jenis FOREIGN KEY (kode_jenis) REFERENCES ag_jenis_toko(kode_jenis),
  CONSTRAINT fk_toko_segment FOREIGN KEY (kode_segment) REFERENCES ag_segment_toko(kode_segment)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgMsStok / AgMsStk1 -> ag_barang : master barang
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_barang (
  kode_barang    VARCHAR(8)  NOT NULL COMMENT 'Nomor_Stok',
  nama_barang    VARCHAR(30) NOT NULL COMMENT 'Nama_Stk',
  kode_group     VARCHAR(5)  NULL     COMMENT 'Group_Stk -> ag_group_barang',
  kode_principal VARCHAR(6)  NULL     COMMENT 'Prin_Stk -> ag_principal',
  kode_principal2 VARCHAR(6) NULL     COMMENT 'Prin2_Stk - "Group Piutang" -> ag_principal',
  kode_unit1     VARCHAR(6)  NULL     COMMENT 'Unit_Stk - satuan I (misal KARTON)',
  kode_unit2     VARCHAR(6)  NULL     COMMENT 'Unit2_Stk - satuan II (misal PCS)',
  isi_unit1      DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Isi_Stk - isi /karton',
  isi_unit2      DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Isi2_Stk - isi II -> I',
  kode_divisi    VARCHAR(3)  NULL     COMMENT 'Div_Stk -> ag_divisi',
  kode_tabel_harga VARCHAR(6) NULL    COMMENT 'TbHrg_Stok - dipakai lookup harga & diskon',
  harga_beli     DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'HrgBl_Stok',
  harga_rata     DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'HrgRt_Stok',
  berat_gram     DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Gram_Stk',
  stok_minimum   DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'QtMin_Stk',
  off_invoice    CHAR(1) NOT NULL DEFAULT 'T' COMMENT 'OI_Stk (Y/T)',
  kompensasi_pct DECIMAL(5,2) NOT NULL DEFAULT 0 COMMENT 'Komp_Stk (%)',
  PRIMARY KEY (kode_barang),
  KEY idx_principal (kode_principal),
  KEY idx_group (kode_group),
  CONSTRAINT fk_barang_group FOREIGN KEY (kode_group) REFERENCES ag_group_barang(kode_group),
  CONSTRAINT fk_barang_divisi FOREIGN KEY (kode_divisi) REFERENCES ag_divisi(kode_divisi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTbTHrg -> ag_tabel_harga : master tabel harga & diskon per grup
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_tabel_harga (
  kode_tabel    VARCHAR(6) NOT NULL COMMENT 'Nomor_THrg',
  grup_harga    VARCHAR(3) NOT NULL COMMENT 'GrHrg_THrg',
  harga         DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Harga_THrg',
  diskon1       DECIMAL(5,2) NOT NULL DEFAULT 0  COMMENT 'Dsc1_THrg',
  PRIMARY KEY (kode_tabel, grup_harga)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTrFktH -> ag_fkt_h : HEADER Nota Penjualan / Faktur
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_fkt_h (
  nomor_fkt     VARCHAR(10) NOT NULL COMMENT 'Nomor_FktH (PK asli)',
  tgl_fkt       DATE NOT NULL         COMMENT 'Tgl_FktH',
  no_po         VARCHAR(10) NULL      COMMENT 'PO_FktH - nomor pesanan pembeli',
  kode_toko     VARCHAR(6) NOT NULL   COMMENT 'Toko_FktH',
  tgl_srj       DATE NULL             COMMENT 'TgSrj_FktH - tanggal surat jalan',
  no_srj        VARCHAR(10) NULL      COMMENT 'NoSrj_FktH - nomor surat jalan',
  tempo_hari    SMALLINT NOT NULL DEFAULT 0 COMMENT 'Due_FktH - tempo bayar (hari)',
  jenis_ppn     CHAR(1) NOT NULL DEFAULT '1' COMMENT 'Disc_FktH - 1/2 sesuai jenis PPN lama',
  kode_sman     VARCHAR(6) NULL       COMMENT 'SlMan_FktH',
  total_jual    DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Jual_FktH - total termasuk PPN',
  total_bayar   DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Bayar_FktH',
  group_prin    VARCHAR(6) NULL       COMMENT 'GPrin_FktH',
  nota_salesman TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Sales_FktH',
  batal         TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Batal_FktH',
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (nomor_fkt),
  KEY idx_toko (kode_toko),
  KEY idx_sman (kode_sman),
  KEY idx_tgl (tgl_fkt),
  CONSTRAINT fk_fkth_toko FOREIGN KEY (kode_toko) REFERENCES ag_toko(kode_toko),
  CONSTRAINT fk_fkth_sman FOREIGN KEY (kode_sman) REFERENCES ag_salesman(kode_sman)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTrFktD -> ag_fkt_d : DETAIL baris barang Nota Penjualan / Faktur
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_fkt_d (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'baris teknis, DBF lama tidak punya PK numerik',
  nomor_fkt     VARCHAR(10) NOT NULL  COMMENT 'Nomor_FktD (FK ke ag_fkt_h)',
  urutan        SMALLINT NOT NULL DEFAULT 0 COMMENT 'urutan baris tampil',
  kode_barang   VARCHAR(8) NOT NULL   COMMENT 'NoStk_FktD',
  kode_gudang   VARCHAR(6) NULL       COMMENT 'GudG_FktD',
  unit          TINYINT NOT NULL DEFAULT 1 COMMENT 'Unit_FktD (1=unit1/besar, 2=unit2/kecil)',
  qty           DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Qty_FktD',
  harga         DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Harga_FktD',
  diskon1       DECIMAL(5,2) NOT NULL DEFAULT 0 COMMENT 'Dsc1_FktD (%)',
  diskon2       DECIMAL(5,2) NOT NULL DEFAULT 0 COMMENT 'Dsc2_FktD (%)',
  nilai_diskon2 DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'NDsc2_FktD',
  jenis         CHAR(1) NULL          COMMENT 'Jns_FktD',
  oi            CHAR(1) NULL          COMMENT 'OI_FktD',
  subtotal      DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'hasil hitung HitFJum() (gross - disc1 - disc2)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_fkt_barang (nomor_fkt, kode_barang),
  KEY idx_barang (kode_barang),
  CONSTRAINT fk_fktd_header FOREIGN KEY (nomor_fkt) REFERENCES ag_fkt_h(nomor_fkt) ON DELETE CASCADE,
  CONSTRAINT fk_fktd_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang),
  CONSTRAINT fk_fktd_gudang FOREIGN KEY (kode_gudang) REFERENCES ag_gudang(kode_gudang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTbBank -> ag_bank : master bank (dipakai saat pembayaran cara Giro)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_bank (
  kode_bank VARCHAR(4)  NOT NULL COMMENT 'Nomor_Bank',
  nama_bank VARCHAR(30) NOT NULL COMMENT 'Nama_Bank',
  PRIMARY KEY (kode_bank)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTrByrD -> ag_pembayaran : Pembayaran Piutang (dari AGE361.PRG)
-- Catatan migrasi: field 'nilai_bayar + cash_discount' dijumlah untuk
-- update Bayar_FktH, meniru persis fungsi Dibayar() di AGCOMMON.PRG.
-- Kode asli pakai soft-delete (Batal_ByrD); di pilot ini disederhanakan
-- jadi hard-delete (lihat catatan di README).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_pembayaran (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tgl_bayar      DATE NOT NULL         COMMENT 'Tgl_ByrD',
  nomor_fkt      VARCHAR(10) NOT NULL  COMMENT 'Nota_ByrD -> ag_fkt_h',
  urutan         TINYINT NOT NULL DEFAULT 1 COMMENT 'Urut_ByrD (1-9, multi bayar nota sama tanggal sama)',
  nilai_bayar    DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Nilai_ByrD',
  cash_discount  DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'CashD_ByrD',
  jenis_bayar    TINYINT NOT NULL DEFAULT 1 COMMENT 'Jenis_ByrD (1=Cash, 2=Giro, 3=Nota Kredit/CN)',
  kode_bank      VARCHAR(4) NULL       COMMENT 'Bank_ByrD - hanya diisi kalau Giro',
  no_giro        VARCHAR(15) NULL      COMMENT 'NoGB_ByrD',
  tgl_tempo_giro DATE NULL             COMMENT 'TgTmp_ByrD',
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tgl_nota_urut (tgl_bayar, nomor_fkt, urutan),
  KEY idx_nota (nomor_fkt),
  CONSTRAINT fk_bayar_fkt FOREIGN KEY (nomor_fkt) REFERENCES ag_fkt_h(nomor_fkt),
  CONSTRAINT fk_bayar_bank FOREIGN KEY (kode_bank) REFERENCES ag_bank(kode_bank)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- MODUL STOK: Penerimaan Barang (AGE210) + Pengambilan/Transfer Antar
-- Gudang (AGE385) + Kartu Stok (ledger, konsep dari AGI200/201)
-- =====================================================================

-- ---------------------------------------------------------------------
-- AgTrLpbH -> ag_lpb_h : HEADER Penerimaan Barang (dari Prinsipal)
-- Catatan: kode asli mewajibkan No.Pesanan cocok dengan AgTrOrdH (modul
-- Purchase Order ke Prinsipal, belum dibangun). Di pilot ini No.Pesanan
-- disederhanakan jadi field referensi bebas (tidak divalidasi ke PO).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_lpb_h (
  nomor_lpb      VARCHAR(6) NOT NULL   COMMENT 'Nomor_LpbH',
  tgl_lpb        DATE NOT NULL         COMMENT 'Tgl_LpbH',
  no_pesanan     VARCHAR(6) NULL       COMMENT 'NoOrd_LpbH - referensi PO, belum divalidasi ke modul Order',
  kode_principal VARCHAR(6) NULL       COMMENT 'Prin_LpbH',
  kode_gudang    VARCHAR(6) NOT NULL   COMMENT 'Gudg_LpbH - gudang tujuan penerimaan',
  no_srj_prin    VARCHAR(10) NULL      COMMENT 'NoSrj_LpbH - no surat jalan dari prinsipal',
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (nomor_lpb),
  CONSTRAINT fk_lpbh_principal FOREIGN KEY (kode_principal) REFERENCES ag_principal(kode_principal),
  CONSTRAINT fk_lpbh_gudang FOREIGN KEY (kode_gudang) REFERENCES ag_gudang(kode_gudang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ag_lpb_d (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_lpb    VARCHAR(6) NOT NULL   COMMENT 'Nomor_LpbD -> ag_lpb_h',
  kode_barang  VARCHAR(8) NOT NULL   COMMENT 'NoStk_LpbD',
  unit         TINYINT NOT NULL DEFAULT 1 COMMENT 'Baru -- 1=satuan besar/karton, 2=satuan kecil/pcs. Qty disimpan APA ADANYA sesuai satuan ini (pola sama dgn ag_fkt_d di Penjualan), dikonversi ke karton cuma pas ditulis ke kartu stok.',
  qty          DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Qty_LpbD (sesuai kolom unit, BUKAN selalu Karton lagi)',
  harga        DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Harga_LpbD',
  PRIMARY KEY (id),
  UNIQUE KEY uq_lpb_barang (nomor_lpb, kode_barang),
  CONSTRAINT fk_lpbd_header FOREIGN KEY (nomor_lpb) REFERENCES ag_lpb_h(nomor_lpb) ON DELETE CASCADE,
  CONSTRAINT fk_lpbd_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTrBpbH -> ag_bpb_h : HEADER Pengambilan / Transfer Barang Antar Gudang
-- (dari AGE385.PRG -- di kode lama dikomentari "Transfer Barang Antar
-- Gudang", tapi inilah yang dipakai salesman "mengambil" stok dari
-- gudang pusat ke gudang kendaraannya masing2 -- lihat Master Salesman
-- field "Kendaraan (Gudang)")
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_bpb_h (
  nomor_bpb        VARCHAR(6) NOT NULL COMMENT 'Nomor_BpbH',
  tgl_bpb          DATE NOT NULL       COMMENT 'Tgl_BpbH',
  kode_gudang_asal VARCHAR(6) NOT NULL COMMENT 'Dari_BpbH',
  kode_gudang_tujuan VARCHAR(6) NOT NULL COMMENT 'Ke_BpbH',
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (nomor_bpb),
  CONSTRAINT fk_bpbh_asal FOREIGN KEY (kode_gudang_asal) REFERENCES ag_gudang(kode_gudang),
  CONSTRAINT fk_bpbh_tujuan FOREIGN KEY (kode_gudang_tujuan) REFERENCES ag_gudang(kode_gudang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ag_bpb_d (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_bpb   VARCHAR(6) NOT NULL   COMMENT 'Nomor_BpbD -> ag_bpb_h',
  kode_barang VARCHAR(8) NOT NULL   COMMENT 'NoStk_BpbD',
  qty         DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Qty_BpbD (satuan Karton/unit1)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_bpb_barang (nomor_bpb, kode_barang),
  CONSTRAINT fk_bpbd_header FOREIGN KEY (nomor_bpb) REFERENCES ag_bpb_h(nomor_bpb) ON DELETE CASCADE,
  CONSTRAINT fk_bpbd_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- ag_kartu_stok : KARTU STOK / stock ledger -- tabel baru, TIDAK ADA
-- padanan langsung di Clipper (kode lama hitung saldo dari gabungan
-- banyak file transaksi tiap kali dibutuhkan, lambat kalau datanya
-- besar). Di sini setiap mutasi stok (Penerimaan / Pengambilan-Transfer,
-- dan nantinya juga pengurangan stok waktu Faktur Penjualan diposting)
-- dicatat sebagai satu baris ledger, supaya saldo tinggal SUM sekali
-- jalan dan riwayatnya (kartu stok per barang) langsung kelihatan.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_kartu_stok (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tanggal      DATE NOT NULL,
  kode_barang  VARCHAR(8) NOT NULL,
  kode_gudang  VARCHAR(6) NOT NULL,
  jenis_mutasi ENUM('MASUK','KELUAR') NOT NULL,
  qty          DECIMAL(12,2) NOT NULL,
  referensi    VARCHAR(20) NOT NULL COMMENT 'mis. LPB-000001, BPB-000002',
  keterangan   VARCHAR(60) NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_barang_gudang (kode_barang, kode_gudang),
  KEY idx_referensi (referensi),
  CONSTRAINT fk_kartu_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang),
  CONSTRAINT fk_kartu_gudang FOREIGN KEY (kode_gudang) REFERENCES ag_gudang(kode_gudang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- ag_opname_h / ag_opname_d : STOK OPNAME (penyesuaian saldo stok sistem
-- ke hasil hitung fisik gudang). Tidak ada padanan langsung di Clipper
-- (stok fisik dulu dicocokkan manual di luar sistem) -- modul baru,
-- mengikuti pola header+detail modul Gudang lainnya.
--
-- Alur approval 2 tahap lewat kolom status:
--   DRAFT  -> header & detail masih bebas diubah/dihapus, BELUM ada baris
--             apapun di kartu stok (masih tahap hitung, belum final).
--   FINAL  -> di-"submit" lewat aksi Finalisasi (butuh Level user <=3,
--             sama seperti hak hapus -- meniru approval oleh supervisor).
--             Begitu FINAL, header & detail terkunci (tidak bisa
--             ubah/tambah/hapus baris) dan selisih tiap baris otomatis
--             tercatat ke kartu stok. Bisa dibatalkan lagi ke DRAFT kalau
--             ternyata masih perlu revisi -- otomatis menghapus balik
--             baris kartu stok yang sudah tercatat.
--
-- qty_sistem = SNAPSHOT saldo sistem (dari ag_kartu_stok) pada saat baris
-- ini terakhir disimpan -- BUKAN dihitung ulang tiap tampil, supaya kalau
-- ada mutasi stok lain masuk setelah opname dibuat, angka "sistem" yang
-- dibandingkan tetap angka saat opname dilakukan.
-- Selisih (qty_fisik - qty_sistem) otomatis jadi 1 baris kartu stok
-- (MASUK kalau lebih, KELUAR kalau kurang) dengan referensi OPN-xxxxxx,
-- lewat pola "hapus referensi lalu tulis ulang" yang sama dgn modul lain
-- -- HANYA dilakukan kalau status dokumennya FINAL.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_opname_h (
  nomor_opname VARCHAR(6) NOT NULL,
  tgl_opname   DATE NOT NULL,
  kode_gudang  VARCHAR(6) NOT NULL COMMENT 'Gudang yang dihitung fisik',
  keterangan   VARCHAR(60) NULL,
  status       ENUM('DRAFT','FINAL') NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT = masih bisa diubah bebas, belum menyentuh kartu stok. FINAL = sudah disetujui (approval), selisih sudah tercatat di kartu stok dan header/detail terkunci sampai dibatalkan finalisasinya.',
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (nomor_opname),
  CONSTRAINT fk_opnameh_gudang FOREIGN KEY (kode_gudang) REFERENCES ag_gudang(kode_gudang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ag_opname_d (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_opname VARCHAR(6) NOT NULL,
  kode_barang  VARCHAR(8) NOT NULL,
  unit         TINYINT NOT NULL DEFAULT 1 COMMENT 'Baru -- satuan yang dipakai isi qty_fisik (1=karton, 2=pcs). qty_sistem SELALU karton (snapshot dari kartu stok) -- selisih dihitung di kode (bukan SQL) supaya qty_fisik dikonversi dulu ke karton kalau unit=2.',
  qty_sistem   DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Snapshot saldo sistem saat baris disimpan, SELALU dalam Karton',
  qty_fisik    DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Hasil hitung fisik di gudang, sesuai kolom unit',
  PRIMARY KEY (id),
  UNIQUE KEY uq_opname_barang (nomor_opname, kode_barang),
  CONSTRAINT fk_opnamed_header FOREIGN KEY (nomor_opname) REFERENCES ag_opname_h(nomor_opname) ON DELETE CASCADE,
  CONSTRAINT fk_opnamed_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- MODUL RETUR: Retur Toko / Credit Note (AGE344, tabel RinH/RinD) dan
-- Retur ke Prinsipal (AGE241, tabel RotH/RotD)
-- =====================================================================

-- ---------------------------------------------------------------------
-- AgTrRinH -> ag_rin_h : HEADER Retur Toko / Credit Note (dari AGE344.PRG,
-- ini versi yang AKTIF dipakai di menu -- ada beberapa versi lama
-- AGE341/342/343/345 di source yang TIDAK dipakai lagi)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_rin_h (
  nomor_rin       VARCHAR(10) NOT NULL COMMENT 'Nomor_RinH (dgn prefix CN)',
  tgl_rin         DATE NOT NULL        COMMENT 'Tgl_RinH',
  kode_toko       VARCHAR(6) NOT NULL  COMMENT 'Toko_RinH',
  jenis_harga     CHAR(1) NOT NULL DEFAULT '1' COMMENT 'Disc_RinH (1/2)',
  kode_gudang     VARCHAR(6) NULL      COMMENT 'Gudg_RinH - gudang tempat barang retur masuk (NULL untuk tipe SALDO_AWAL, karena tidak ada barang fisik yang gerak)',
  kode_sman       VARCHAR(6) NULL      COMMENT 'SlMan_RinH',
  tukar_barang    TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Tukar_RinH (Y=tukar barang, N=potong nota)',
  nomor_nota_asli VARCHAR(10) NULL     COMMENT 'Nota_RinH - referensi nota asli (opsional, TIDAK divalidasi batas 0.6%% seperti kode asli)',
  nilai_nota_asli DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'NilNt_RinH',
  nilai           DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Untuk tipe NORMAL: dihitung dari total detail. Untuk tipe SALDO_AWAL: diisi langsung manual (tidak ada baris barang).',
  tipe            ENUM('NORMAL','SALDO_AWAL') NOT NULL DEFAULT 'NORMAL' COMMENT 'SALDO_AWAL = dari AGE307.PRG "Nota Kredit Awal", entry saldo migrasi tanpa detail barang',
  batal           TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Batal_RinH',
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (nomor_rin),
  KEY idx_toko (kode_toko),
  CONSTRAINT fk_rinh_toko FOREIGN KEY (kode_toko) REFERENCES ag_toko(kode_toko),
  CONSTRAINT fk_rinh_gudang FOREIGN KEY (kode_gudang) REFERENCES ag_gudang(kode_gudang),
  CONSTRAINT fk_rinh_sman FOREIGN KEY (kode_sman) REFERENCES ag_salesman(kode_sman)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ag_rin_d (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_rin   VARCHAR(10) NOT NULL  COMMENT 'Nomor_RinD -> ag_rin_h',
  kode_barang VARCHAR(8) NOT NULL   COMMENT 'NoStk_RinD',
  qty         DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Qty_RinD',
  harga       DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Harga_RinD',
  subtotal    DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'qty x harga (disederhanakan, tanpa tingkatan diskon)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_rin_barang (nomor_rin, kode_barang),
  CONSTRAINT fk_rind_header FOREIGN KEY (nomor_rin) REFERENCES ag_rin_h(nomor_rin) ON DELETE CASCADE,
  CONSTRAINT fk_rind_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- AgTrRotH -> ag_rot_h : HEADER Retur ke Prinsipal (dari AGE241.PRG)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_rot_h (
  nomor_rot      VARCHAR(10) NOT NULL COMMENT 'Nomor_RotH',
  tgl_rot        DATE NOT NULL        COMMENT 'Tgl_RotH',
  kode_principal VARCHAR(6) NOT NULL  COMMENT 'Prin_RotH',
  kode_gudang    VARCHAR(6) NOT NULL  COMMENT 'Gudg_RotH - gudang asal (barang keluar dari sini)',
  nilai          DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'dihitung dari total detail',
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (nomor_rot),
  CONSTRAINT fk_roth_principal FOREIGN KEY (kode_principal) REFERENCES ag_principal(kode_principal),
  CONSTRAINT fk_roth_gudang FOREIGN KEY (kode_gudang) REFERENCES ag_gudang(kode_gudang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ag_rot_d (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_rot   VARCHAR(10) NOT NULL  COMMENT 'Nomor_RotD -> ag_rot_h',
  kode_barang VARCHAR(8) NOT NULL   COMMENT 'NoStk_RotD',
  qty         DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Qty_RotD',
  harga       DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Harga_RotD',
  subtotal    DECIMAL(15,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_rot_barang (nomor_rot, kode_barang),
  CONSTRAINT fk_rotd_header FOREIGN KEY (nomor_rot) REFERENCES ag_rot_h(nomor_rot) ON DELETE CASCADE,
  CONSTRAINT fk_rotd_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- MODUL CETAK: Profil Perusahaan (untuk kop surat PDF) + kolom No. Seri
-- Faktur Pajak di Nota Penjualan
-- =====================================================================

-- ---------------------------------------------------------------------
-- ag_pengaturan : profil perusahaan, 1 baris tetap (id=1), dipakai
-- sebagai kop surat/kepala dokumen di semua cetakan PDF (Nota & Faktur
-- Pajak). Tidak ada padanan tabel di Clipper (dulu hardcode di kode
-- report masing-masing).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ag_pengaturan (
  id               TINYINT UNSIGNED NOT NULL DEFAULT 1,
  nama_perusahaan  VARCHAR(80) NOT NULL DEFAULT '',
  alamat           VARCHAR(150) NOT NULL DEFAULT '',
  kota             VARCHAR(50) NOT NULL DEFAULT '',
  telp             VARCHAR(40) NOT NULL DEFAULT '',
  npwp             VARCHAR(30) NOT NULL DEFAULT '',
  nama_penandatangan VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'nama yang muncul di kolom ttd cetakan',
  -- Data khusus PKP untuk Faktur Pajak (dari AgCtl asli: NmFp2_Ctl, AlFP2_Ctl,
  -- NPWP2_Ctl, NPKP2_Ctl, TPKP2_Ctl, TdTg2_Ctl -- kode asli sengaja pisahkan
  -- ini dari profil perusahaan umum karena kadang beda, mis. NPWP pusat vs cabang)
  nama_pkp         VARCHAR(80) NOT NULL DEFAULT '' COMMENT 'NmFp2_Ctl - nama PKP di Faktur Pajak, bisa beda dari nama_perusahaan',
  alamat_pkp       VARCHAR(150) NOT NULL DEFAULT '' COMMENT 'AlFP2_Ctl',
  npwp_pkp         VARCHAR(30) NOT NULL DEFAULT '' COMMENT 'NPWP2_Ctl',
  nomor_pkp        VARCHAR(40) NOT NULL DEFAULT '' COMMENT 'NPKP2_Ctl - Nomor Pengukuhan PKP',
  tanggal_pkp      DATE NULL COMMENT 'TPKP2_Ctl - Tanggal Pengukuhan PKP',
  penandatangan_pkp VARCHAR(60) NOT NULL DEFAULT '' COMMENT 'TdTg2_Ctl - nama penandatangan khusus Faktur Pajak',
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO ag_pengaturan (id) VALUES (1) ON DUPLICATE KEY UPDATE id = id;

-- ---------------------------------------------------------------------
-- Kolom tambahan di ag_fkt_h untuk No. Seri Faktur Pajak (NSFP).
-- PENTING: field ini murni catatan/referensi internal. NSFP resmi harus
-- diminta dari DJP dan Faktur Pajak yang sah SECARA HUKUM tetap wajib
-- diterbitkan lewat aplikasi e-Faktur/Coretax DJP -- lihat catatan di
-- README bagian "Cetak Faktur Pajak".
-- ---------------------------------------------------------------------
ALTER TABLE ag_fkt_h ADD COLUMN nomor_seri_fp VARCHAR(30) NULL COMMENT 'NSFP 17 digit (PER-11/PJ/2025), di-generate otomatis oleh Coretax saat faktur disubmit -- kolom ini cuma catatan referensi setelahnya, bukan input sebelum transaksi';

-- =====================================================================
-- MODUL UTILITY: User / Login (dari AGE012.PRG "Users Maintenance",
-- tabel asli AgTbUser + AgTbPass terpisah -- di web ini digabung 1 tabel,
-- password di-hash pakai bcrypt, bukan disimpan di tabel terpisah kayak
-- kode asli)
-- =====================================================================
CREATE TABLE IF NOT EXISTS ag_user (
  kode_user      VARCHAR(8) NOT NULL   COMMENT 'Kode_User',
  nama_user      VARCHAR(30) NOT NULL  COMMENT 'Nama_User',
  password_hash  VARCHAR(100) NOT NULL COMMENT 'dulu di tabel AgTbPass terpisah, di sini digabung + di-hash bcrypt',
  level_user     TINYINT NOT NULL DEFAULT 5 COMMENT 'Level_User: 1 (tertinggi/admin) s/d 5 (terendah), meniru kode asli',
  hari_transaksi SMALLINT NOT NULL DEFAULT 7 COMMENT 'Day_User - batas hari mundur untuk entry transaksi',
  aktif          TINYINT(1) NOT NULL DEFAULT 1,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (kode_user)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- MODUL PURCHASE ORDER: Surat Pesanan Barang ke Prinsipal (AGE200.PRG)
-- Dipakai untuk validasi field "No. Pesanan" di Penerimaan Barang
-- (AGE210.PRG) -- lihat perubahan di modules/penerimaan/model.js
-- =====================================================================
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS ag_ord_h (
  nomor_ord      VARCHAR(6) NOT NULL COMMENT 'Nomor_OrdH',
  tgl_ord        DATE NOT NULL        COMMENT 'Tgl_OrdH',
  kode_principal VARCHAR(6) NOT NULL  COMMENT 'Prin_OrdH',
  nilai          DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'dihitung dari total detail',
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (nomor_ord),
  CONSTRAINT fk_ordh_principal FOREIGN KEY (kode_principal) REFERENCES ag_principal(kode_principal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ag_ord_d (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_ord   VARCHAR(6) NOT NULL   COMMENT 'Nomor_OrdD -> ag_ord_h',
  kode_barang VARCHAR(8) NOT NULL   COMMENT 'NoStk_OrdD',
  qty         DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Qty_OrdD (Karton)',
  harga       DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Harga_OrdD',
  subtotal    DECIMAL(15,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ord_barang (nomor_ord, kode_barang),
  CONSTRAINT fk_ordd_header FOREIGN KEY (nomor_ord) REFERENCES ag_ord_h(nomor_ord) ON DELETE CASCADE,
  CONSTRAINT fk_ordd_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sambungkan Penerimaan Barang ke Purchase Order (dulu no_pesanan cuma
-- teks bebas -- lihat catatan README "Purchase Order ke Prinsipal")
SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE ag_lpb_h ADD CONSTRAINT fk_lpbh_order FOREIGN KEY (no_pesanan) REFERENCES ag_ord_h(nomor_ord);

SET FOREIGN_KEY_CHECKS = 1;



-- =====================================================================
-- MODUL BUDGET & TARGET: dari AGR970.PRG (Budget Aktivitas, tabel
-- AgTrBudg) dan AGE395/AGR969.PRG (Target Penjualan Salesman, tabel
-- AgTrTrgt). Dipakai laporan Analisa Penjualan untuk bandingkan
-- rencana vs realisasi.
-- =====================================================================
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS ag_budget_barang (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  kode_barang VARCHAR(8) NOT NULL   COMMENT 'NoStk_Budg',
  tgl_awal    DATE NOT NULL         COMMENT 'TgAw_Budg',
  tgl_akhir   DATE NOT NULL         COMMENT 'TgAk_Budg',
  qty         DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Qty_Budg',
  harga       DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Harga_Budg',
  nilai       DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Nilai_Budg = qty x harga',
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_budget_barang_periode (kode_barang, tgl_awal, tgl_akhir),
  CONSTRAINT fk_budget_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ag_target_salesman (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tahun             SMALLINT NOT NULL      COMMENT 'Tahun_Trgt',
  bulan             TINYINT NOT NULL       COMMENT 'Bulan_Trgt (1-12)',
  kode_sman         VARCHAR(6) NOT NULL    COMMENT 'SMan_Trgt',
  target_penjualan  DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Jual_Trgt',
  target_cn         DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'CN_Trgt',
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_target_periode_sman (tahun, bulan, kode_sman),
  CONSTRAINT fk_target_sman FOREIGN KEY (kode_sman) REFERENCES ag_salesman(kode_sman)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- BONUS BARANG di Nota Penjualan (dari AgTrBnus, dipakai AGE350.PRG &
-- dicetak oleh AGR984.PRG "Tanda Terima Bonus"). Barang bonus/gratis
-- yang menyertai nota, SENGAJA dipisah dari ag_fkt_d supaya tidak ikut
-- masuk perhitungan DPP/PPN (barang gratis tidak dikenai pajak jual).
-- =====================================================================
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS ag_fkt_bonus (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_fkt   VARCHAR(10) NOT NULL  COMMENT 'Nomor_Bnus -> ag_fkt_h',
  kode_barang VARCHAR(8) NOT NULL   COMMENT 'NoStk_Bnus',
  qty         DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Qty_Bnus',
  PRIMARY KEY (id),
  UNIQUE KEY uq_bonus_barang (nomor_fkt, kode_barang),
  CONSTRAINT fk_bonus_header FOREIGN KEY (nomor_fkt) REFERENCES ag_fkt_h(nomor_fkt) ON DELETE CASCADE,
  CONSTRAINT fk_bonus_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- HARGA BARANG 3 LEVEL (T.O / Kanvas / Motoris), tiap level punya
-- histori harga per tanggal berlaku. Ditambahkan atas permintaan user
-- -- tidak ada padanan langsung yang jelas di kode Clipper asli (yang
-- ada cuma 20 slot generik HRG1_STOK..HRG20_STOK di AgMsStok, tanpa
-- penamaan level T.O/Kanvas/Motoris eksplisit), jadi dibuat tabel baru
-- yang bersih sesuai spesifikasi yang diminta.
-- =====================================================================
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS ag_harga_barang (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  kode_barang  VARCHAR(8) NOT NULL,
  level        ENUM('TO','KANVAS','MOTORIS') NOT NULL COMMENT 'TO = Harga T.O, KANVAS = Harga Kanvas, MOTORIS = Harga Motoris',
  tgl_berlaku  DATE NOT NULL,
  harga_jual   DECIMAL(15,2) NOT NULL DEFAULT 0,
  harga_beli   DECIMAL(15,2) NOT NULL DEFAULT 0,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_harga_barang (kode_barang, level, tgl_berlaku),
  KEY idx_barang_level (kode_barang, level),
  CONSTRAINT fk_harga_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- ag_biaya_operasional : BIAYA OPERASIONAL, pencatatan pengeluaran biaya
-- sehari-hari (gaji, sewa, listrik, transport, dll). Tidak ada padanan
-- di kode Clipper asli -- sistem lama tidak punya pencatatan biaya sama
-- sekali, itu semua dikerjakan manual di aplikasi akuntansi terpisah
-- (lihat README bagian 20 & 25c). Ditambahkan khusus supaya Laporan
-- Rugi Laba Sederhana (Laba Kotor - Biaya Operasional) punya data biaya
-- untuk dikurangkan -- BUKAN pengganti pembukuan resmi, tidak ada
-- jurnal/COA/buku besar di sini, cuma catatan pengeluaran flat.
-- =====================================================================
CREATE TABLE IF NOT EXISTS ag_biaya_operasional (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tanggal     DATE NOT NULL,
  kategori    VARCHAR(30) NOT NULL COMMENT 'Bebas isi, mis. Gaji, Sewa, Listrik, Transport, ATK, Lain-lain',
  keterangan  VARCHAR(100) NULL,
  jumlah      DECIMAL(15,2) NOT NULL DEFAULT 0,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_tanggal (tanggal),
  KEY idx_kategori (kategori)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- ag_log_aktivitas : LOG AKTIVITAS -- siapa login (berhasil/gagal),
-- siapa simpan/hapus apa & kapan. Tidak ada padanan di kode Clipper asli
-- (DOS single-user per sesi, jejak siapa-ngapain tidak pernah jadi
-- kebutuhan) -- baru relevan sekarang karena aplikasi berbasis web bisa
-- diakses banyak user bersamaan.
--
-- `kode_user`/`nama_user` SENGAJA disimpan sebagai teks lepas (snapshot),
-- BUKAN foreign key ke ag_user -- supaya log tetap utuh & terbaca walau
-- user-nya kemudian diubah namanya atau dihapus dari Users Maintenance.
-- =====================================================================
CREATE TABLE IF NOT EXISTS ag_log_aktivitas (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  waktu       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  kode_user   VARCHAR(10) NULL,
  nama_user   VARCHAR(50) NULL,
  aksi        VARCHAR(20) NOT NULL COMMENT 'LOGIN_BERHASIL, LOGIN_GAGAL, LOGOUT, SIMPAN, HAPUS',
  modul       VARCHAR(40) NULL COMMENT 'Segmen path pertama, mis. stok-opname, penjualan',
  path        VARCHAR(255) NULL COMMENT 'Path lengkap request, buat telusur detail',
  ip_address  VARCHAR(45) NULL,
  keterangan  VARCHAR(255) NULL,
  PRIMARY KEY (id),
  KEY idx_waktu (waktu),
  KEY idx_kode_user (kode_user),
  KEY idx_aksi (aksi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- ag_log_harga_barang : RIWAYAT PERUBAHAN HARGA BARANG -- beda dari
-- ag_harga_barang (yang nyimpen "harga apa yg BERLAKU per tanggal
-- berlaku tertentu", dan kalau baris yg sama disimpan ulang nilai lama
-- ke-TIMPA tanpa jejak), tabel ini nyatet EVENT perubahannya sendiri:
-- siapa yang ubah, kapan (waktu asli/wall-clock, bukan tanggal
-- berlaku), dan nilai lama -> baru. Ditulis otomatis tiap kali harga di
-- level manapun (T.O/Kanvas/Motoris) ditambah atau diedit lewat menu
-- Master Barang -- lihat modules/barang/model.js -> tambahHarga().
-- =====================================================================
CREATE TABLE IF NOT EXISTS ag_log_harga_barang (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  waktu             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  kode_user         VARCHAR(10) NULL,
  nama_user         VARCHAR(50) NULL,
  kode_barang       VARCHAR(8) NOT NULL,
  level             VARCHAR(10) NOT NULL COMMENT 'TO, KANVAS, atau MOTORIS',
  tgl_berlaku       DATE NOT NULL,
  harga_jual_lama   DECIMAL(15,2) NULL COMMENT 'NULL kalau baris baru (belum pernah ada sebelumnya)',
  harga_jual_baru   DECIMAL(15,2) NOT NULL,
  harga_beli_lama   DECIMAL(15,2) NULL,
  harga_beli_baru   DECIMAL(15,2) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_kode_barang (kode_barang),
  KEY idx_waktu (waktu)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- ag_log_notifikasi : LOG NOTIFIKASI WHATSAPP OTOMATIS -- rekap
-- penjualan harian ke owner, reminder jatuh tempo ke toko, alert stok
-- kritis ke pembelian (lihat modules/notifikasi). Beda dari
-- ag_log_aktivitas (yang nyatet aksi USER di aplikasi), ini nyatet
-- PENGIRIMAN pesan keluar -- sukses/gagal, ke nomor mana, isi ringkas
-- apa -- dipakai juga buat cegah reminder yang sama dikirim berkali-kali
-- di hari yang sama/berdekatan (lihat cekSudahDikirim() di model).
-- =====================================================================
CREATE TABLE IF NOT EXISTS ag_log_notifikasi (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  waktu       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  jenis       VARCHAR(30) NOT NULL COMMENT 'REKAP_HARIAN, REMINDER_JATUH_TEMPO, STOK_KRITIS, TEST',
  referensi   VARCHAR(30) NULL COMMENT 'Mis. nomor_fkt utk reminder jatuh tempo -- dipakai cek dedup',
  tujuan_nomor VARCHAR(20) NULL,
  tujuan_nama VARCHAR(50) NULL,
  pesan       TEXT NULL,
  status      VARCHAR(10) NOT NULL COMMENT 'SUKSES atau GAGAL',
  keterangan  VARCHAR(255) NULL COMMENT 'Pesan error kalau gagal',
  PRIMARY KEY (id),
  KEY idx_waktu (waktu),
  KEY idx_jenis_referensi (jenis, referensi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- ag_barcode_barang : BARCODE per barang -- tidak ada di Clipper asli
-- (dulu semua input manual ketik kode_barang). 1 barang bisa punya LEBIH
-- DARI 1 barcode (tabel terpisah, bukan 1 kolom di ag_barang) karena di
-- dunia nyata kemasan karton & kemasan pcs/eceran biasanya punya barcode
-- FISIK YANG BEDA di produk yang sama -- scan salah satunya harus tetap
-- kenali barang & satuannya dengan benar. `unit` menentukan itu discan
-- dari kemasan besar (1) atau kecil (2), dipakai auto-isi kolom Unit di
-- form Penerimaan/Stok Opname.
-- =====================================================================
CREATE TABLE IF NOT EXISTS ag_barcode_barang (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  kode_barang VARCHAR(8) NOT NULL,
  barcode     VARCHAR(30) NOT NULL,
  unit        TINYINT NOT NULL DEFAULT 1 COMMENT '1=satuan besar/karton, 2=satuan kecil/pcs',
  keterangan  VARCHAR(50) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_barcode (barcode),
  KEY idx_kode_barang (kode_barang),
  CONSTRAINT fk_barcode_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- ag_por_h / ag_por_d : PESANAN DARI TOKO ("Purchase Order" toko ke
-- kita, padanan AGTRPORH/AGTRPORD di Clipper asli -- ternyata salah
-- satu tabel PALING AKTIF dipakai di data referensi asli, 1287
-- header + 8631 baris detail, tapi belum sempat dikonversi sebelumnya).
--
-- Ini TAHAP SEBELUM Nota Penjualan -- toko pesan dulu (PO), baru nanti
-- dipenuhi lewat 1 atau beberapa Nota (bisa dicicil, field QTTER_PORD
-- di data asli = "qty terkirim" menunjukkan pemenuhan boleh sebagian).
-- Sama persis konsepnya dengan Order Prinsipal -> Penerimaan Barang
-- (ag_ord_h/ag_ord_d -> ag_lpb_h/ag_lpb_d), cuma arahnya kebalik: di
-- sini yang "memesan" adalah toko, dan yang "memenuhi" adalah Nota
-- Penjualan (ag_fkt_h/ag_fkt_d, lewat kolom no_po yang sudah ada dari
-- awal tapi sebelum ini cuma teks bebas, belum tersambung ke tabel
-- manapun).
--
-- Qty terkirim SENGAJA tidak disimpan sbg kolom running counter --
-- dihitung ulang live dari ag_fkt_d yang no_po-nya cocok (pola yang
-- sama dipakai qty_diterima di Order Prinsipal), supaya tidak ada
-- resiko data ke-outdate/nggak sinkron.
-- =====================================================================
CREATE TABLE IF NOT EXISTS ag_por_h (
  nomor_por  VARCHAR(6) NOT NULL COMMENT 'Nomor_PorH',
  tgl_por    DATE NOT NULL        COMMENT 'Tgl_PorH',
  kode_toko  VARCHAR(6) NOT NULL  COMMENT 'Toko_PorH',
  nilai      DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'dihitung dari total detail',
  batal      TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Baru -- soft cancel kalau toko batalkan pesanan sebelum ada nota sama sekali',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (nomor_por),
  CONSTRAINT fk_porh_toko FOREIGN KEY (kode_toko) REFERENCES ag_toko(kode_toko)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ag_por_d (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomor_por   VARCHAR(6) NOT NULL   COMMENT 'Nomor_PorD -> ag_por_h',
  kode_barang VARCHAR(8) NOT NULL   COMMENT 'NoStk_PorD',
  unit        TINYINT NOT NULL DEFAULT 1 COMMENT 'Unit_PorD -- 1=karton, 2=pcs, pola sama dgn modul lain',
  qty         DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Qty_PorD, sesuai kolom unit',
  harga       DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Harga_PorD',
  subtotal    DECIMAL(15,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_por_barang (nomor_por, kode_barang),
  CONSTRAINT fk_pord_header FOREIGN KEY (nomor_por) REFERENCES ag_por_h(nomor_por) ON DELETE CASCADE,
  CONSTRAINT fk_pord_barang FOREIGN KEY (kode_barang) REFERENCES ag_barang(kode_barang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- ag_histori_harga_hpp : HISTORI HARGA JUAL & HPP PER TANGGAL, padanan
-- AGTBTBHG (histori harga jual, 12.568 baris) + AGTBTHPP (histori HPP,
-- 11.250 baris) di data referensi Clipper -- diimpor dari backup DBF
-- April 2024 (lihat db/histori-harga-hpp.sql, digenerate dari data
-- asli, BUKAN data contoh/dummy).
--
-- INI YANG BIKIN Laba Kotor (batch 22) BISA JAUH LEBIH AKURAT utk
-- transaksi lama -- sebelumnya HPP selalu pakai harga_rata TERKINI
-- (estimasi), sekarang bisa ambil HPP yang BENERAN BERLAKU pada
-- tanggal transaksi itu terjadi. Kalau tidak ada baris histori yang
-- cocok (barang baru / tanggal sebelum histori paling awal), tetap
-- fallback ke harga_rata terkini seperti sebelumnya -- lihat
-- modules/laporan/model.js -> ambilBarisMargin().
--
-- `hpp2` disertakan buat kelengkapan referensi tapi HAMPIR SELALU 0 di
-- data asli (cuma 2,9% baris yang keisi) -- HPP1 yang jadi acuan utama.
-- `harga_beli` di TBHG asli ternyata TIDAK PERNAH keisi sama sekali di
-- data referensi (selalu kosong) -- kolom disediakan tapi boleh NULL.
-- =====================================================================
CREATE TABLE IF NOT EXISTS ag_histori_harga_hpp (
  kode_barang VARCHAR(8) NOT NULL,
  tanggal     DATE NOT NULL,
  harga_jual  DECIMAL(15,2) NULL COMMENT 'Padanan JUAL_TBHG',
  harga_beli  DECIMAL(15,2) NULL COMMENT 'Padanan BELI_TBHG -- hampir selalu kosong di data asli',
  hpp1        DECIMAL(15,2) NULL COMMENT 'Padanan HPP1_THPP -- INI yang dipakai Laba Kotor',
  hpp2        DECIMAL(15,2) NULL COMMENT 'Padanan HPP2_THPP -- referensi saja, jarang keisi',
  PRIMARY KEY (kode_barang, tanggal),
  KEY idx_kode_tanggal (kode_barang, tanggal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
