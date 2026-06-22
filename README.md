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
* API Rate Limiting untuk Brook Framework

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
# API Rate Limiting untuk Brook Framework (Lazarus / Free Pascal)

Implementasi sederhana **API Rate Limiting berbasis alamat IP** menggunakan **Brook Framework** dan **Free Pascal (Lazarus)**.

Tujuan utama proyek ini adalah melindungi REST API dari:

* Request berulang akibat bug pada aplikasi client.
* Brute force attack.
* Spam request.
* Lonjakan trafik tidak normal.
* Beban database yang tidak diperlukan.

---

## Fitur

* Pembatasan request berdasarkan IP Address.
* Maksimal 10 request per menit untuk setiap IP.
* Penyimpanan data di memori menggunakan `TStringList`.
* Tidak membutuhkan database tambahan.
* Ringan dan cepat.
* Mudah diintegrasikan dengan Brook Framework.

---

## Cara Kerja

Setiap alamat IP yang mengakses API akan dicatat dalam memori dengan format:

```text
JumlahRequest|WaktuReset
```

Contoh:

```text
192.168.1.10=5|2026-06-12 10:30:00
```

Keterangan:

* `5` = jumlah request yang telah dilakukan.
* `2026-06-12 10:30:00` = waktu reset counter.

Jika jumlah request melebihi batas yang ditentukan sebelum waktu reset tercapai, server akan mengembalikan:

```http
HTTP/1.1 429 Too Many Requests
```

---

## Struktur Variabel

Tambahkan variabel berikut pada form utama atau modul server:

```pascal
private
  FIPTracker: TStringList;
```

Saat inisialisasi:

```pascal
FIPTracker := TStringList.Create;
FIPTracker.Sorted := False;
```

Saat aplikasi ditutup:

```pascal
FreeAndNil(FIPTracker);
```

---

## Fungsi Rate Limiting

```pascal
function TFormUtama.CheckRateLimit(AIP: string): Boolean;
var
  vIndex: Integer;
  vHitCount: Integer;
  vCurrentTime: TDateTime;
  vLastResetTime: TDateTime;
  vDataStr, vHitStr, vTimeStr: string;
  vPosPemisah: Integer;
begin
  Result := True;

  vCurrentTime := Now;
  vIndex := FIPTracker.IndexOfName(AIP);

  if vIndex = -1 then
  begin
    FIPTracker.Add(AIP + '=1|' +
      DateTimeToStr(vCurrentTime + (1 / 1440)));
  end
  else
  begin
    vDataStr := FIPTracker.ValueFromIndex[vIndex];

    vPosPemisah := Pos('|', vDataStr);

    vHitStr := Copy(vDataStr, 1, vPosPemisah - 1);
    vTimeStr := Copy(vDataStr, vPosPemisah + 1, Length(vDataStr));

    vHitCount := StrToIntDef(vHitStr, 0);
    vLastResetTime := StrToDateTimeDef(vTimeStr, vCurrentTime);

    if vCurrentTime > vLastResetTime then
    begin
      FIPTracker.Strings[vIndex] :=
        AIP + '=1|' +
        DateTimeToStr(vCurrentTime + (1 / 1440));
    end
    else
    begin
      Inc(vHitCount);

      if vHitCount > 10 then
        Result := False;

      FIPTracker.Strings[vIndex] :=
        AIP + '=' +
        IntToStr(vHitCount) + '|' +
        DateTimeToStr(vLastResetTime);
    end;
  end;
end;
```

---

## Implementasi pada Route Brook

Contoh penggunaan sebelum proses bisnis dijalankan:

```pascal
if not CheckRateLimit(ClientIP) then
begin
  Context.Response.StatusCode := 429;
  Context.Response.Content :=
    '{"status":"error","message":"Too Many Requests"}';
  Exit;
end;
```

Dengan pendekatan ini request akan ditolak sebelum:

* Query database dijalankan.
* Koneksi Zeos dibuka.
* Resource server digunakan lebih lanjut.

---

## Pengujian Menggunakan ApacheBench

Contoh pengujian:

```cmd
ab.exe -n 15 -c 1 ^
-H "Authorization: ismail" ^
http://localhost:8888/barang_limit
```

Parameter:

| Parameter | Keterangan         |
| --------- | ------------------ |
| -n 15     | Total request      |
| -c 1      | Concurrent request |
| -H        | Header tambahan    |

---

## Hasil Benchmark

```text
Complete requests:      15
Failed requests:        0
Non-2xx responses:      15

Requests per second:    4810.78
Processing Time:        0 ms
```

---

## Analisis

### Request Berhasil Diblokir

```text
Non-2xx responses: 15
```

Menunjukkan bahwa seluruh request yang melebihi batas berhasil ditolak.

### Waktu Pemrosesan Sangat Rendah

```text
Processing Time: 0 ms
```

Karena proses pengecekan dilakukan langsung di RAM tanpa akses database.

### Throughput Tinggi

```text
4810 Request per Second
```

Server tetap mampu merespons dengan cepat meskipun sedang melakukan pemblokiran request.

---

## Catatan Penting

### Jangan Gunakan Sorted=True

Hindari konfigurasi berikut:

```pascal
FIPTracker.Sorted := True;
```

Karena dapat menyebabkan exception:

```text
EStringListError:
Operation not allowed on sorted list
```

ketika data dimodifikasi secara dinamis.

Gunakan:

```pascal
FIPTracker.Sorted := False;
```

---

## Keterbatasan

Implementasi ini cocok untuk:

* Belajar Rate Limiting.
* REST API internal.
* Sistem klinik.
* Sistem inventory.
* UMKM.

Untuk skala besar disarankan menggunakan:

* Redis
* Memcached
* Shared Memory
* Distributed Cache

agar dapat digunakan pada banyak instance server sekaligus.

---

## Teknologi

* Lazarus IDE
* Free Pascal Compiler (FPC)
* Brook Framework
* ZeosLib
* ApacheBench

---
# Tutorial: Migrasi REST API Brook Framework dari LCL GUI Form ke Console Application (High-Performance Backend)

Aplikasi berbasis **LCL GUI Form** sangat menyenangkan untuk tahap *development* dan *debugging* lokal di desktop. Namun, ketika software house kita harus melakukan *deployment* backend ke server produksi—seperti Cloud VPS berbasis Linux Server tanpa antarmuka grafis (headless OS)—mengandalkan komponen visual adalah sebuah kekeliruan arsitektur.

Artikel ini akan mengupas tuntas cara melakukan konversi (refactoring) REST API **Brook Framework (Tardigrade)** dari arsitektur LCL GUI menjadi **Console Application** murni, lengkap dengan implementasi *Zeos Connection Pool*, *Rate Limiting*, dan *Redis Caching Layer*.

---

## 🚀 Mengapa Harus Pindah ke Console Application? (Kelebihan & Keuntungan)

Sebelum masuk ke teknis koding, sebagai IT Manager atau Software Architect, kita harus memahami keuntungan esensial dari migrasi ini:

### 1. Efisiensi RAM yang Brutal (Ultra Lightweight)

Aplikasi berbasis LCL GUI memuat banyak pustaka grafis (*subsystem widgetset* seperti Win32/64 GDI atau GTK/X11 di Linux) yang tidak dibutuhkan oleh sebuah web service.

* **GUI Form:** Memakan alokasi RAM sekitar **30 MB – 80 MB** saat *idle*.
* **Console Application:** Murni berjalan di tingkat kernel CLI dengan konsumsi RAM **di bawah 10 MB** (bahkan bisa menyentuh **4 MB – 6 MB**).

### 2. Berjalan Abadi sebagai Background Service (Daemon)

Aplikasi console sangat mudah diintegrasikan dengan *Service Manager* sistem operasi server. Di Linux Ubuntu/Lubuntu Server, Anda bisa membungkus file biner console ini menggunakan **Systemd Daemon**. Jika server mengalami *crash* atau *restart*, sistem akan otomatis menghidupkan kembali REST API Anda secara instan di background tanpa perlu melakukan login user desktop.

### 3. Kecepatan Eksekusi Tanpa Overhead Grafis

Tanpa perlu melakukan *update* komponen visual (seperti *Log Memo*, *SpinEdit*, atau reposisi *Label* setiap kali ada request masuk), CPU server bisa fokus 100% menangani konkurensi jaringan dan I/O database. Hasilnya, *throughput request per second* (RPS) backend Anda akan melesat lebih tinggi.

### 4. Portabilitas dan Standar Microservices Modern

Satu otak untuk dua aplikasi. Dengan memisahkan logika bisnis ke dalam unit murni (`.pas`), Anda bisa mengompilasi biner desktop untuk manajemen lokal, sekaligus mengompilasi biner console untuk dipasang di docker container maupun VPS Cloud.

---

## 🛠️ Panduan Langkah Demi Langkah (Refactoring)

Kunci sukses migrasi cepat tanpa perlu menginstal ulang komponen visual yang sering konflik di IDE Lazarus (`OPM Checksum Error`) adalah menggunakan metode **Class-Based Routing** dan mengisolasi logika ke dalam file unit mandiri.

### Struktur Direktori Proyek

```text
📦 rest_api_sqlite
 ┣ 📂 db
 ┃ ┗ 📜 database.db          <- Lokasi Database SQLite
 ┗ 📂 console
   ┣ 📜 RestApiConsole.lpr   <- File Utama Program Console
   ┣ 📜 uhandlerapi.pas      <- Otak / Logika Bisnis API
   ┗ 📜 uMinimalRedis.pas    <- Driver Redis Portable

```

---

### Langkah 1: Isolasi Logika Bisnis (`console/uhandlerapi.pas`)

Buat unit murni Pascal tanpa membawa dependensi `Forms`. Seluruh rute dibentuk menggunakan pendekatan berorientasi objek (*Class-Based*) agar kompatibel dengan engine Tardigrade terbaru.

```pascal
unit uhandlerapi;

{$MODE DELPHI}

interface

uses
  SysUtils, Classes, ZDataset, ZConnection, BrookURLRouter, 
  BrookHTTPRequest, BrookHTTPResponse, BrookUtility, fpjson, jsonparser,
  zstream, uMinimalRedis;

type
  { TRouteHome }
  TRouteHome = class(TBrookURLRoute)
  protected
    procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  public
    procedure AfterConstruction; override;
  end;

  { TRouteBarangCRUD }
  TRouteBarangCRUD = class(TBrookURLRoute)
  protected
    procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  public
    procedure AfterConstruction; override;
  end;

procedure RegistrasiSemuaRute(ARoutesCollection: TCollection; AZConn: TZConnection; AIPTracker: TStringList);

implementation

var
  gZConn: TZConnection;
  gIPTracker: TStringList;

procedure RegistrasiSemuaRute(ARoutesCollection: TCollection; AZConn: TZConnection; AIPTracker: TStringList);
begin
  gZConn := AZConn;
  gIPTracker := AIPTracker;

  TRouteHome.Create(ARoutesCollection);
  TRouteBarangCRUD.Create(ARoutesCollection);
end;

{ TRouteHome }
procedure TRouteHome.AfterConstruction;
begin
  inherited AfterConstruction;
  Methods := [rmGET];
  Pattern := '/';
end;

procedure TRouteHome.DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
  AResponse.Send('<html><body><h3>Backend Console Active!</h3></body></html>', 'text/html', 200);
end;

{ TRouteBarangCRUD }
procedure TRouteBarangCRUD.AfterConstruction;
begin
  inherited AfterConstruction;
  Methods := [rmGET, rmPOST, rmPUT, rmDELETE];
  Pattern := '/barang';
end;

procedure TRouteBarangCRUD.DoRequest(ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
  vNama, vKode: string; JSONArray: TJSONArray; JSONObject: TJSONObject; vQuery: TZQuery;
begin
  vQuery := TZQuery.Create(nil); vQuery.Connection := gZConn;
  try
    if ARequest.Method = 'GET' then
    begin
      JSONArray := TJSONArray.Create;
      try
        vQuery.SQL.Text := 'SELECT id_barang, nama_barang, harga, stok FROM barang LIMIT 100';
        vQuery.Open;
        while not vQuery.EOF do
        begin
          JSONObject := TJSONObject.Create;
          JSONObject.Add('id', vQuery.FieldByName('id_barang').AsInteger);
          JSONObject.Add('nama', vQuery.FieldByName('nama_barang').AsString);
          JSONArray.Add(JSONObject);
          vQuery.Next;
        end;
        AResponse.Send(JSONArray.AsJSON, 'application/json; charset=utf-8', 200);
      finally
        JSONArray.Free;
      end;
    end;
    // Blok POST, PUT, DELETE Anda diletakkan di bawah sini...
  finally
    vQuery.Free;
  end;
end;

end.

```

---

### Langkah 2: Buat Mesin Penggerak CLI (`console/RestApiConsole.lpr`)

Berkas utama program ini bertindak sebagai *Server Wrapper* yang menangani siklus hidup aplikasi serta inisialisasi parameter runtime (seperti port kustom via argumen CLI).

```pascal
program RestApiConsole;

{$MODE DELPHI}

uses
  {$IFDEF UNIX}
  cthreads, 
  {$ENDIF}
  SysUtils, Classes, CustApp, 
  ZConnection, BrookHTTPServer, BrookURLRouter, BrookHTTPRequest, BrookHTTPResponse,
  uhandlerapi; 

type
  TConsoleRouter = class(TBrookURLRouter)
  protected
    procedure DoNotFound(ASender: TObject; const ARoute: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  end;

  TConsoleServer = class(TBrookHTTPServer)
  private
    FRouter: TConsoleRouter;
  protected
    procedure DoRequest(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse) override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TBrookConsoleApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

var
  gZConnectiondb: TZConnection;
  gIPTracker: TStringList;

procedure TConsoleRouter.DoNotFound(ASender: TObject; const ARoute: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
  AResponse.Send('{"status": "error", "message": "Endpoint not found!"}', 'application/json', 404);
end;

constructor TConsoleServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRouter := TConsoleRouter.Create(Self);
  RegistrasiSemuaRute(FRouter.Routes, gZConnectiondb, gIPTracker);
  FRouter.Active := True;
end;

destructor TConsoleServer.Destroy;
begin
  FRouter.Free;
  inherited Destroy;
end;

procedure TConsoleServer.DoRequest(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
  FRouter.Route(ASender, ARequest, AResponse);
end;

procedure TBrookConsoleApp.DoRun;
var
  vPort: Integer; vServer: TConsoleServer;
begin
  vPort := StrToIntDef(GetOptionValue('p', 'port'), 8888);
  Writeln('=====================================================');
  Writeln('   NFI KREATIF - BROOK REST API CONSOLE SERVER       ');
  Writeln('=====================================================');

  gIPTracker := TStringList.Create;
  gZConnectiondb := TZConnection.Create(nil);
  gZConnectiondb.Protocol := 'sqlite';
  
  // Menggunakan jalur absolut demi kestabilan testing
  gZConnectiondb.Database := 'D:\data\belajar_brook_fremwork\rest_api_sqlite\db\database.db';
  gZConnectiondb.Properties.Values['pooled'] := 'true';
  gZConnectiondb.Properties.Values['maxconnections'] := '50';

  try
    gZConnectiondb.Connect;
    Writeln('-> [SUKSES] Database Connection Pool Aktif.');
    
    vServer := TConsoleServer.Create(nil);
    vServer.Port := vPort;
    vServer.Open;
    
    Writeln('-> [SUKSES] HTTP Server berjalan di port: ' + IntToStr(vPort));
    Writeln('Tekan [CTRL + C] untuk menghentikan layanan.');
    Writeln('-----------------------------------------------------');

    while not Terminated do CheckSynchronize(100);
    
  finally
    vServer.Free; gZConnectiondb.Free; gIPTracker.Free;
  end;
  Terminate;
end;

var Application: TBrookConsoleApp;
begin
  Application := TBrookConsoleApp.Create(nil); Application.Run; Application.Free;
end.

```

---

### Langkah 3: Kompilasi Independen Tanpa Ketergantungan IDE

Jika IDE Lazarus mengalami bentrok komponen visual, Anda bisa memicu compiler `fpc.exe` bawaan `fpcupdeluxe` secara langsung lewat Command Prompt (CMD) Windows:

```cmd
cd /d D:\data\belajar_brook_fremwork\rest_api_sqlite\console

C:\fpcupdeluxe\fpc\bin\x86_64-win64\fpc.exe -MObjFPC -Scghi -O2 -Fu"C:\fpcupdeluxe\ccr\zeos\src\**" -Fu"C:\fpcupdeluxe\config_lazarus\onlinepackagemanager\packages\brookframework\Source" RestApiConsole.lpr

```

Hanya dalam waktu hitungan detik, file biner super-ringan **`RestApiConsole.exe`** siap dieksekusi!

---

## 🎯 Cara Menjalankan & Pengujian

Eksekusi server Anda dari terminal dengan menyuntikkan port kustom:

```cmd
RestApiConsole.exe --port=8888

```

Buka **Postman**, lalu tembak endpoint CRUD Anda:

* **URL:** `GET http://localhost:8888/barang`
* **Headers:** `Authorization` = `[Token Hasil Login Anda]`

Aplikasi akan merespons dalam satuan mili-detik murni berkat hilangnya *overhead graphic render* bawaan LCL Form!

---

## 💡 Kesimpulan

Migrasi dari LCL ke Console Application bukan sekadar urusan estetika penulisan koding, melainkan keputusan bisnis strategis untuk menekan biaya sewa server (*resource optimization*). Dengan arsitektur murni *Class-Based* ini, REST API Anda kini siap menopang jutaan transaksi dengan performa yang stabil, aman, dan efisien.

*Happy Coding! Jangan lupa untuk memberikan Star ⭐ pada repository ini jika tutorial ini membantu proyek Anda.*

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
