# REST API Dasar dengan Brook Framework & SQLite / zeos

Project ini adalah contoh implementasi **REST API** performa tinggi menggunakan bahasa pemrograman **Pascal** via **Brook Framework** dan database **SQLite**. Aplikasi ini dirancang menggunakan arsitektur GUI di Lazarus, namun berfungsi penuh sebagai web server backend yang menyediakan fitur autentikasi (*Simple Auth* & *Token Auth*) serta manajemen data produk (**CRUD**).

---

## 🚀 Fitur Utama

* **Performa Native & Ringan:** Dibangun di atas bahasa kompilaasi Pascal dengan konsumsi memori (*footprint*) yang sangat minim.
* **Dua Metode Autentikasi:** * `/login` (Autentikasi Sederhana/Kredensial dasar)
* `/auth` (Manajemen Token dinamis berbasis GUID yang tersimpan di SQLite)


* **Full CRUD:** Manajemen produk pada endpoint `/produk` yang sudah diproteksi oleh *Middleware Auth*.
* **Keamanan:** Dilengkapi dengan *Parameterized Query* untuk mencegah celah *SQL Injection*.
* Zeos Connection Pool
* Verifikasi Kakas Penguji (ApacheBench)
* Kompresi di Brook Framework

---

## 🛠️ Prasyarat (Prerequisites)

Sebelum menjalankan atau melakukan *compile* project ini, pastikan lingkungan pengembangan kamu sudah terpasang:

1. **Lazarus IDE** (Direkomendasikan menggunakan FPC versi 3.2.2 atau yang lebih baru).
2. **Brook Framework Package** (Dapat dipasang melalui *Online Package Manager* di Lazarus).
3. Library **SQLite3** (`sqlite3.dll` untuk Windows atau paket `libsqlite3` untuk pengguna Linux/Lubuntu).

---

## 📂 Struktur Database

Project ini menggunakan database SQLite (`database.db`). Pastikan file database berada dalam satu folder dengan file executable aplikasi. Struktur dasarnya adalah sebagai berikut:

### Tabel Users

```sql
CREATE TABLE users (
    id_user INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    token TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

```

### Tabel Barang

```sql
CREATE TABLE barang (
    id_barang INTEGER PRIMARY KEY AUTOINCREMENT,
    nama_barang TEXT NOT NULL,
    kategori TEXT,
    harga REAL NOT NULL,
    stok INTEGER DEFAULT 0,
    id_user_admin INTEGER,
    FOREIGN KEY (id_user_admin) REFERENCES users (id_user)
);

```

---

## 📖 Dokumentasi Endpoint API

Secara default, server berjalan pada `http://localhost:8888`.

### 1. Autentikasi Sederhana

* **Endpoint:** `/login`
* **Method:** `POST`
* **Request Body (JSON):**
```json
{
  "username": "budi_admin",
  "password": "password123"
}

```


* **Response Sukses (200 OK):**
```json
{
  "status": "success",
  "message": "Login Berhasil",
  "user_id": 1,
  "username": "budi_admin"
}

```



---

### 2. Autentikasi Berbasis Token (Parent `/auth`)

Gunakan endpoint ini untuk menghasilkan token dinamis berbasis GUID yang nantinya digunakan untuk mengakses data produk.

* **Endpoint:** `/auth`
* **Method:** `POST`
* **Request Body (JSON):**
```json
{
  "username": "budi_admin",
  "password": "password123"
}

```


* **Response Sukses (200 OK):**
```json
{
  "status": "success",
  "token": "4a1c2f...b31f5392d5d46ef5",
  "username": "budi_admin"
}

```



> **Catatan Keamanan:** Simpan nilai `token` yang dikembalikan dari endpoint ini. Kamu wajib mengirimkannya pada HTTP Header di setiap request CRUD berikutnya dengan format:
> `Authorization: <token_kamu>`

---

### 3. Manajemen Produk (CRUD - Memerlukan Token Authorization)

Semua request di bawah ini wajib menyertakan Header: `Authorization: <token>`

#### A. Ambil Semua / Cari Produk (GET)

* **Endpoint:** `/produk` atau `/produk?nama=laptop` atau `/produk?kode=1`
* **Method:** `GET`
* **Response Sukses (200 OK):**
```json
[
  {
    "id": 1,
    "nama": "Laptop ASUS",
    "harga": 7500000,
    "stok": 10
  }
]

```



#### B. Tambah Produk Baru (POST)

* **Endpoint:** `/produk`
* **Method:** `POST`
* **Request Body (JSON):**
```json
{
  "nama": "Kopi Hitam Nikmat",
  "kategori": "Minuman",
  "harga": 5000,
  "stok": 50,
  "id_user": 1
}

```


* **Response Sukses (201 Created):**
```json
{
  "status": "success",
  "message": "Data berhasil disimpan"
}

```



#### C. Perbarui Data Produk (PUT)

* **Endpoint:** `/produk`
* **Method:** `PUT`
* **Request Body (JSON):**
```json
{
  "id": 1,
  "nama": "Kopi Hitam Super Nikmat (Updated)",
  "kategori": "Minuman",
  "harga": 6000,
  "stok": 25
}

```


* **Response Sukses (200 OK):**
```json
{
  "status": "success",
  "message": "Data berhasil diperbarui"
}

```



#### D. Hapus Produk (DELETE)

* **Endpoint:** `/produk?id=1`
* **Method:** `DELETE`
* **Response Sukses (200 OK):**
```json
{
  "status": "success",
  "message": "Data dengan ID 1 berhasil dihapus"
}

```



---

## 💻 Cara Menjalankan Aplikasi

1. Buka berkas proyek `.lpi` menggunakan Lazarus IDE.
2. Lakukan *Compile* dan *Run* (tekan tombol **F9**).
3. Pada jendela aplikasi GUI yang muncul, tentukan port server (default: `8888`), lalu klik tombol **Start**.
4. Gunakan aplikasi penguji API seperti **Postman** atau **Insomnia** untuk menembak endpoint di atas.

---

## Metodologi Pengujian Beban (Load Testing)

Pengujian performa backend dilakukan menggunakan pendekatan *Zero-Dependency Testing*, yaitu memanfaatkan perkakas portable bawaan Apache HTTP Server (**ApacheBench**) tanpa perlu menginstal runtime atau package manager pihak ketiga seperti Node.js/NPM di lingkungan PC Server/Development.

### Langkah 1: Verifikasi Kakas Penguji (ApacheBench)

Sebelum menjalankan skrip pengujian, pastikan bahwa berkas eksekusi ApacheBench (`ab.exe`) sudah tersedia di sistem Anda. 

1. **Jalur Akses Default (XAMPP):** Jika Anda menggunakan XAMPP untuk Windows, alat ini secara default sudah terinstal dan berada pada direktori:
   ```text
   C:\xampp\apache\bin\ab.exe
   cara Testing C:\xampp\apache\bin\ab.exe -n 100 -c 10 -H "Authorization: ismail" http://localhost:8888/barang

---

# ⚡ Optimasi REST API dengan Kompresi Gzip / Deflate

Pada aplikasi REST API yang menangani ribuan data, ukuran payload JSON sering menjadi faktor utama yang mempengaruhi kecepatan respons dan konsumsi bandwidth.

Brook Framework menyediakan fitur kompresi HTTP secara native melalui algoritma **Gzip** dan **Deflate**, sehingga data JSON dapat dipadatkan terlebih dahulu sebelum dikirim ke client.

Keuntungan penggunaan kompresi:

* Mengurangi ukuran payload hingga 60%–80%.
* Menghemat bandwidth server.
* Mempercepat transfer data pada jaringan internet.
* Mengurangi waktu tunggu (latency) aplikasi Android, Web, maupun Desktop.
* Sangat cocok untuk aplikasi Klinik, SIMRS, Inventory, ERP, dan POS.

---

## Membuat Endpoint Kompresi

Sebagai contoh, project ini menyediakan endpoint:

```text
/barang_kompres
```

Endpoint tersebut bekerja sama seperti endpoint:

```text
/barang
```

namun respons JSON akan dikompresi secara otomatis menggunakan Gzip atau Deflate.

---

## Aktivasi Kompresi di Brook Framework

Aktivasi kompresi cukup dilakukan sebelum memanggil method `Send()`:

```pascal
AResponse.Compression := True;
```

Contoh implementasi:

```pascal
vJSON := JSONArray.AsJSON;

// Aktifkan kompresi otomatis
AResponse.Compression := True;

// Kirim JSON ke client
AResponse.Send(
  vJSON,
  'application/json; charset=utf-8',
  200
);
```

Brook Framework akan secara otomatis:

1. Memeriksa header `Accept-Encoding` dari client.
2. Mengompresi payload menggunakan Gzip atau Deflate.
3. Menambahkan header HTTP yang sesuai.
4. Mengirim hasil kompresi ke client.

---

## Cara Pengujian Menggunakan ApacheBench

### Benchmark Tanpa Kompresi

```cmd
C:\xampp\apache\bin\ab.exe ^
-n 100 ^
-c 10 ^
-H "Authorization: ismail" ^
http://localhost:8888/barang
```

Perhatikan hasil berikut:

```text
Transfer rate
HTML transferred
Time per request
```

---

### Benchmark Dengan Kompresi

Tambahkan header:

```text
Accept-Encoding: gzip, deflate
```

Lalu jalankan:

```cmd
C:\xampp\apache\bin\ab.exe ^
-n 100 ^
-c 10 ^
-H "Authorization: ismail" ^
-H "Accept-Encoding: gzip, deflate" ^
http://localhost:8888/barang_kompres
```

---

## Contoh Hasil Benchmark

### Endpoint Biasa

```text
Complete requests:      100
Failed requests:        0
HTML transferred:       15200000 bytes
Transfer rate:          3600 KB/sec
```

### Endpoint Dengan Kompresi

```text
Complete requests:      100
Failed requests:        0
HTML transferred:       3200000 bytes
Transfer rate:          980 KB/sec
```

---

## Analisis Hasil

Pada contoh di atas:

| Parameter          | Tanpa Kompresi | Dengan Kompresi |
| ------------------ | -------------- | --------------- |
| Ukuran Transfer    | 15.2 MB        | 3.2 MB          |
| Penghematan Data   | -              | 78.9%           |
| Beban Jaringan     | Tinggi         | Rendah          |
| Cocok Untuk Mobile | Cukup          | Sangat Cocok    |

Semakin besar ukuran JSON yang dikirim, semakin besar pula manfaat kompresi yang diperoleh.

---

## Kapan Sebaiknya Menggunakan Kompresi?

Sangat direkomendasikan untuk endpoint yang mengembalikan:

* Data master produk
* Data pasien
* Data rekam medis
* Data inventory
* Data laporan
* Data transaksi
* Data sinkronisasi aplikasi mobile

Contoh:

```text
/barang
/pasien
/rekammedis
/transaksi
/master_produk
/sinkronisasi
```

---

## Kapan Tidak Perlu Menggunakan Kompresi?

Tidak terlalu diperlukan untuk:

* Endpoint login
* Endpoint validasi token
* Endpoint dengan respons sangat kecil (< 1 KB)

Contoh:

```text
/login
/auth
/ping
/healthcheck
```

Karena biaya CPU untuk melakukan kompresi terkadang lebih besar daripada keuntungan yang diperoleh dari ukuran data yang sangat kecil.

---

## Kesimpulan

Dengan hanya menambahkan satu baris kode:

```pascal
AResponse.Compression := True;
```

REST API Brook Framework dapat:

* Mengurangi bandwidth hingga 80%.
* Mempercepat pengiriman data.
* Mengoptimalkan performa aplikasi mobile.
* Mengurangi beban jaringan server.
* Meningkatkan skalabilitas sistem.

Fitur ini sangat direkomendasikan untuk implementasi REST API skala produksi yang menangani data dalam jumlah besar.

---

## Benchmark yang Direkomendasikan

Untuk simulasi beban ringan:

```cmd
ab.exe -n 100 -c 10
```

Untuk simulasi beban menengah:

```cmd
ab.exe -n 1000 -c 50
```

Untuk simulasi beban tinggi:

```cmd
ab.exe -n 5000 -c 100
```

Pastikan selalu membandingkan hasil endpoint normal dan endpoint terkompresi agar manfaat optimasi dapat terlihat secara nyata.

---

## Dikembangkan Oleh

**Ismail Hasan**
Programmer Lazarus Pascal, Android Developer, dan Konsultan Pengembangan Sistem Informasi.

Website:
https://www.ismailhasan.web.id

Software House:
NFI Kreatif

Fokus pengembangan:

* REST API Brook Framework
* Lazarus Pascal Desktop
* Android Pascal (LAMW)
* SIMRS & Sistem Klinik
* Inventory & ERP
* Integrasi Database MySQL, MariaDB, PostgreSQL, SQLite

