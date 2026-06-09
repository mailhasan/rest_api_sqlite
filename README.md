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

## dikembangkan oleh [Ismail Hasan](https://www.google.com/search?q=https://ismailhasan.web.id) - **Nfi Kreatif**
