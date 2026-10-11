# News API — Dokumentasi

REST API untuk aplikasi berita (latihan). Dibangun di atas **Supabase** (PostgreSQL + Edge Function).

- **Versi:** 1.0.0
- **Format data:** JSON (UTF-8)
- **Base URL:**

```
https://<project-ref>.supabase.co/functions/v1/api
```

> Ganti `<project-ref>` dengan ID project Supabase Anda. Semua contoh di dokumen ini memakai `{{BASE_URL}}` sebagai pengganti base URL.

---

## Daftar Isi

1. [Ringkasan Endpoint](#1-ringkasan-endpoint)
2. [Autentikasi](#2-autentikasi)
3. [Format Response](#3-format-response)
4. [Pagination](#4-pagination)
5. [Status Code](#5-status-code)
6. [Model Data](#6-model-data)
7. [Endpoint Publik](#7-endpoint-publik)
8. [Endpoint Admin](#8-endpoint-admin)
9. [Data Dummy](#9-data-dummy)
10. [Catatan Penting](#10-catatan-penting)

---

## 1. Ringkasan Endpoint

### Publik (tanpa autentikasi)

| Method | Endpoint | Keterangan |
|---|---|---|
| `GET` | `/` | Info API dan daftar endpoint |
| `GET` | `/categories` | Daftar semua kategori |
| `GET` | `/categories/{slug}` | Detail satu kategori |
| `GET` | `/authors` | Daftar semua penulis |
| `GET` | `/authors/{slug}` | Detail satu penulis |
| `GET` | `/articles` | Daftar artikel (pagination, filter, pencarian, sorting) |
| `GET` | `/articles/featured` | Artikel pilihan |
| `GET` | `/articles/breaking` | Breaking news |
| `GET` | `/articles/{idOrSlug}` | Detail artikel (views bertambah 1) |
| `GET` | `/articles/{idOrSlug}/related` | Artikel terkait (kategori sama) |
| `GET` | `/articles/{idOrSlug}/comments` | Daftar komentar artikel |
| `POST` | `/articles/{idOrSlug}/comments` | Kirim komentar |

### Admin (wajib header `x-api-key`)

| Method | Endpoint | Keterangan |
|---|---|---|
| `POST` | `/articles` | Buat artikel baru |
| `PUT` | `/articles/{id}` | Ubah artikel (parsial) |
| `DELETE` | `/articles/{id}` | Hapus artikel |
| `DELETE` | `/comments/{id}` | Hapus komentar |

---

## 2. Autentikasi

Endpoint **publik** tidak memerlukan header apa pun.

Endpoint **admin** wajib menyertakan header berikut:

```
x-api-key: <ADMIN_API_KEY>
```

`ADMIN_API_KEY` adalah nilai secret yang Anda buat di **Supabase Dashboard → Edge Functions → Secrets**.

Jika header tidak ada atau nilainya salah, API mengembalikan `401 Unauthorized`:

```json
{
  "success": false,
  "message": "Unauthorized: header x-api-key tidak valid atau tidak ada"
}
```

> ⚠️ Jangan menyimpan `ADMIN_API_KEY` di aplikasi Flutter yang dirilis ke publik. Key di dalam aplikasi bisa diekstrak. Gunakan key admin hanya untuk latihan, Postman, atau panel admin pribadi.

---

## 3. Format Response

Semua response memakai struktur yang sama.

### Sukses

```json
{
  "success": true,
  "message": "OK",
  "data": { },
  "meta": { }
}
```

| Field | Tipe | Keterangan |
|---|---|---|
| `success` | boolean | Selalu `true` |
| `message` | string | Pesan singkat |
| `data` | object / array / null | Isi data |
| `meta` | object | Hanya ada pada endpoint ber-pagination |

### Gagal

```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "title": "title wajib diisi, 5-200 karakter"
  }
}
```

| Field | Tipe | Keterangan |
|---|---|---|
| `success` | boolean | Selalu `false` |
| `message` | string | Penjelasan error |
| `errors` | object | Hanya ada pada error validasi. Key = nama field, value = pesan |

---

## 4. Pagination

Endpoint yang mendukung pagination: `GET /articles` dan `GET /articles/{idOrSlug}/comments`.

| Query | Default | Batas | Keterangan |
|---|---|---|---|
| `page` | `1` | min 1 | Nomor halaman |
| `limit` | `10` | 1–50 | Jumlah data per halaman |

Nilai di luar batas otomatis disesuaikan (misalnya `limit=100` menjadi `50`). Nilai yang bukan angka memakai default.

Response berisi objek `meta`:

```json
"meta": {
  "page": 1,
  "limit": 10,
  "total": 16,
  "total_pages": 2,
  "has_next": true
}
```

| Field | Keterangan |
|---|---|
| `page` | Halaman saat ini |
| `limit` | Jumlah data per halaman |
| `total` | Total seluruh data yang cocok dengan filter |
| `total_pages` | Jumlah halaman |
| `has_next` | `true` jika masih ada halaman berikutnya |

Jika `page` melebihi jumlah halaman, `data` berupa array kosong `[]`.

---

## 5. Status Code

| Code | Arti | Kapan terjadi |
|---|---|---|
| `200` | OK | Request berhasil |
| `201` | Created | Artikel atau komentar berhasil dibuat |
| `400` | Bad Request | Body bukan JSON object yang valid, `id` bukan angka, format parameter salah |
| `401` | Unauthorized | Header `x-api-key` tidak ada atau salah |
| `404` | Not Found | Endpoint, artikel, kategori, penulis, atau komentar tidak ditemukan |
| `405` | Method Not Allowed | Endpoint ada, tetapi method HTTP-nya tidak didukung |
| `409` | Conflict | `slug` artikel sudah dipakai |
| `422` | Unprocessable Entity | Validasi gagal, `category_id` / `author_id` tidak ada, tidak ada field yang diubah |
| `500` | Internal Server Error | Kesalahan tak terduga di server |

---

## 6. Model Data

### Category

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | integer | ID kategori |
| `name` | string | Nama kategori |
| `slug` | string | Slug unik, dipakai di URL dan filter |
| `description` | string \| null | Deskripsi |
| `article_count` | integer | Jumlah artikel published di kategori ini |

### Author

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | integer | ID penulis |
| `name` | string | Nama penulis |
| `slug` | string | Slug unik |
| `bio` | string \| null | Biografi singkat |
| `avatar_url` | string \| null | URL foto profil |
| `article_count` | integer | Jumlah artikel published oleh penulis ini |

### Article (versi daftar)

Dipakai oleh `GET /articles`, `/articles/featured`, `/articles/breaking`, dan `/articles/{idOrSlug}/related`.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | integer | ID artikel |
| `title` | string | Judul |
| `slug` | string | Slug unik |
| `summary` | string \| null | Ringkasan |
| `thumbnail_url` | string \| null | URL gambar |
| `tags` | string[] | Daftar tag |
| `is_featured` | boolean | Artikel pilihan |
| `is_breaking` | boolean | Breaking news |
| `views` | integer | Jumlah dilihat |
| `published_at` | string (ISO 8601) \| null | Waktu terbit |
| `category` | object | `{ id, name, slug }` |
| `author` | object | `{ id, name, slug, avatar_url }` |

### Article (versi detail)

Dipakai oleh `GET /articles/{idOrSlug}`, `POST /articles`, dan `PUT /articles/{id}`. Berisi semua field versi daftar, ditambah:

| Field | Tipe | Keterangan |
|---|---|---|
| `content` | string | Isi lengkap artikel. Paragraf dipisahkan `\n\n` |
| `status` | string | `published` atau `draft` |
| `updated_at` | string (ISO 8601) | Waktu terakhir diubah |
| `author.bio` | string \| null | Biografi penulis (tambahan di objek `author`) |

### Comment

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | integer | ID komentar |
| `name` | string | Nama pengirim |
| `content` | string | Isi komentar |
| `created_at` | string (ISO 8601) | Waktu dikirim |

---

## 7. Endpoint Publik

### 7.1 Info API

```
GET /
```

Mengembalikan nama, versi, dan daftar endpoint.

```bash
curl "{{BASE_URL}}/"
```

```json
{
  "success": true,
  "message": "Selamat datang di News API",
  "data": {
    "name": "News API",
    "version": "1.0.0",
    "endpoints": {
      "public": ["GET    /categories", "..."],
      "admin_requires_x_api_key": ["POST   /articles", "..."]
    }
  }
}
```

---

### 7.2 Daftar Kategori

```
GET /categories
```

Diurutkan berdasarkan nama (A–Z).

```bash
curl "{{BASE_URL}}/categories"
```

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": 3,
      "name": "Ekonomi",
      "slug": "ekonomi",
      "description": "Harga pasar, UMKM, dan keuangan pribadi.",
      "article_count": 3
    },
    {
      "id": 4,
      "name": "Hiburan",
      "slug": "hiburan",
      "description": "Musik, film, dan acara budaya.",
      "article_count": 2
    }
  ]
}
```

---

### 7.3 Detail Kategori

```
GET /categories/{slug}
```

| Parameter | Lokasi | Tipe | Keterangan |
|---|---|---|---|
| `slug` | path | string | Slug kategori, misalnya `teknologi` |

```bash
curl "{{BASE_URL}}/categories/teknologi"
```

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": 1,
    "name": "Teknologi",
    "slug": "teknologi",
    "description": "Berita seputar startup, gadget, dan dunia pemrograman.",
    "article_count": 4
  }
}
```

**Error:** `404` — `Kategori tidak ditemukan`

---

### 7.4 Daftar Penulis

```
GET /authors
```

Diurutkan berdasarkan nama (A–Z).

```bash
curl "{{BASE_URL}}/authors"
```

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": 4,
      "name": "Andi Firmansyah",
      "slug": "andi-firmansyah",
      "bio": "Penulis rubrik hiburan dan kesehatan.",
      "avatar_url": "https://ui-avatars.com/api/?name=Andi+Firmansyah&background=8E44AD&color=fff&size=256",
      "article_count": 4
    }
  ]
}
```

---

### 7.5 Detail Penulis

```
GET /authors/{slug}
```

| Parameter | Lokasi | Tipe | Keterangan |
|---|---|---|---|
| `slug` | path | string | Slug penulis, misalnya `rina-pratiwi` |

```bash
curl "{{BASE_URL}}/authors/rina-pratiwi"
```

**Error:** `404` — `Penulis tidak ditemukan`

---

### 7.6 Daftar Artikel

```
GET /articles
```

Hanya menampilkan artikel berstatus `published`.

| Query | Tipe | Default | Keterangan |
|---|---|---|---|
| `page` | integer | `1` | Nomor halaman |
| `limit` | integer | `10` | Data per halaman (maks 50) |
| `category` | string | – | Filter slug kategori, misalnya `olahraga` |
| `author` | string | – | Filter slug penulis, misalnya `budi-santoso` |
| `tag` | string | – | Filter satu tag, misalnya `tips` |
| `search` | string | – | Cari di `title` dan `summary` (tidak peka huruf besar/kecil) |
| `sort` | string | `latest` | `latest` (terbaru), `oldest` (terlama), `popular` (views terbanyak) |

Semua filter bisa digabung.

```bash
# Terbaru, halaman 1
curl "{{BASE_URL}}/articles"

# Terpopuler di kategori olahraga
curl "{{BASE_URL}}/articles?category=olahraga&sort=popular"

# Cari "motor" dengan tag "tips", 5 per halaman
curl "{{BASE_URL}}/articles?search=motor&tag=tips&limit=5"
```

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": 4,
      "title": "Uji Coba Internet Satelit untuk Sekolah di Daerah Terpencil Dimulai",
      "slug": "uji-coba-internet-satelit-sekolah-terpencil",
      "summary": "Tahap awal uji coba menyasar dua puluh sekolah yang selama ini belum terjangkau jaringan seluler stabil.",
      "thumbnail_url": "https://picsum.photos/seed/internet-satelit-sekolah/800/450",
      "tags": ["internet", "pendidikan"],
      "is_featured": false,
      "is_breaking": true,
      "views": 410,
      "published_at": "2026-10-11T06:25:00.000000+00:00",
      "category": { "id": 1, "name": "Teknologi", "slug": "teknologi" },
      "author": {
        "id": 1,
        "name": "Rina Pratiwi",
        "slug": "rina-pratiwi",
        "avatar_url": "https://ui-avatars.com/api/?name=Rina+Pratiwi&background=0D8ABC&color=fff&size=256"
      }
    }
  ],
  "meta": { "page": 1, "limit": 10, "total": 16, "total_pages": 2, "has_next": true }
}
```

**Error:** `422` jika `sort` tidak valid:

```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": { "sort": "sort harus latest, oldest, atau popular" }
}
```

> Filter `category` atau `author` dengan slug yang tidak ada **tidak** menghasilkan 404. Hasilnya `data: []` dengan `total: 0`.

---

### 7.7 Artikel Pilihan

```
GET /articles/featured
```

Artikel dengan `is_featured = true`, diurutkan dari yang terbaru. Tanpa pagination.

| Query | Tipe | Default | Keterangan |
|---|---|---|---|
| `limit` | integer | `5` | Jumlah data (1–20) |

```bash
curl "{{BASE_URL}}/articles/featured?limit=3"
```

Response: `data` berisi array Article (versi daftar).

---

### 7.8 Breaking News

```
GET /articles/breaking
```

Artikel dengan `is_breaking = true`, diurutkan dari yang terbaru. Parameter dan format response sama dengan [Artikel Pilihan](#77-artikel-pilihan).

```bash
curl "{{BASE_URL}}/articles/breaking"
```

---

### 7.9 Detail Artikel

```
GET /articles/{idOrSlug}
```

| Parameter | Lokasi | Tipe | Keterangan |
|---|---|---|---|
| `idOrSlug` | path | integer / string | ID artikel (`5`) atau slug (`garuda-muda-juara-liga-futsal-pelajar`) |

Setiap kali endpoint ini dipanggil, `views` artikel bertambah 1. Nilai `views` di response sudah termasuk tambahan tersebut.

```bash
curl "{{BASE_URL}}/articles/garuda-muda-juara-liga-futsal-pelajar"
# atau
curl "{{BASE_URL}}/articles/5"
```

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": 5,
    "title": "Klub Garuda Muda Juara Liga Futsal Pelajar",
    "slug": "garuda-muda-juara-liga-futsal-pelajar",
    "summary": "Gol di menit-menit akhir memastikan Garuda Muda mengangkat trofi setelah laga final yang berlangsung ketat.",
    "content": "Klub Garuda Muda keluar sebagai juara liga futsal pelajar ...\n\nPelatih Garuda Muda mengatakan ...\n\nGelar ini menjadi yang pertama ...",
    "thumbnail_url": "https://picsum.photos/seed/futsal-garuda-muda/800/450",
    "tags": ["futsal", "pelajar"],
    "is_featured": true,
    "is_breaking": false,
    "views": 2101,
    "status": "published",
    "published_at": "2026-10-11T02:15:00.000000+00:00",
    "updated_at": "2026-10-11T07:15:00.000000+00:00",
    "category": { "id": 2, "name": "Olahraga", "slug": "olahraga" },
    "author": {
      "id": 2,
      "name": "Budi Santoso",
      "slug": "budi-santoso",
      "bio": "Meliput olahraga dan otomotif sejak lebih dari sepuluh tahun.",
      "avatar_url": "https://ui-avatars.com/api/?name=Budi+Santoso&background=E67E22&color=fff&size=256"
    }
  }
}
```

**Error:** `404` — `Artikel tidak ditemukan` (termasuk jika artikel berstatus `draft`)

---

### 7.10 Artikel Terkait

```
GET /articles/{idOrSlug}/related
```

Artikel lain dari kategori yang sama, tidak termasuk artikel itu sendiri, diurutkan dari yang terbaru.

| Query | Tipe | Default | Keterangan |
|---|---|---|---|
| `limit` | integer | `4` | Jumlah data (1–10) |

```bash
curl "{{BASE_URL}}/articles/garuda-muda-juara-liga-futsal-pelajar/related?limit=2"
```

Response: `data` berisi array Article (versi daftar).

**Error:** `404` — `Artikel tidak ditemukan`

---

### 7.11 Daftar Komentar

```
GET /articles/{idOrSlug}/comments
```

Diurutkan dari yang terbaru. Mendukung [pagination](#4-pagination).

```bash
curl "{{BASE_URL}}/articles/garuda-muda-juara-liga-futsal-pelajar/comments"
```

```json
{
  "success": true,
  "message": "OK",
  "data": [
    {
      "id": 4,
      "name": "Putri",
      "content": "Gol di menit akhir itu luar biasa.",
      "created_at": "2026-10-11T04:15:00.000000+00:00"
    },
    {
      "id": 3,
      "name": "Rizky",
      "content": "Selamat untuk Garuda Muda! Final yang menegangkan.",
      "created_at": "2026-10-11T03:15:00.000000+00:00"
    }
  ],
  "meta": { "page": 1, "limit": 10, "total": 2, "total_pages": 1, "has_next": false }
}
```

**Error:** `404` — `Artikel tidak ditemukan`

---

### 7.12 Kirim Komentar

```
POST /articles/{idOrSlug}/comments
```

**Header:** `Content-Type: application/json`

**Body:**

| Field | Tipe | Wajib | Aturan |
|---|---|---|---|
| `name` | string | ✅ | 2–50 karakter |
| `content` | string | ✅ | 3–500 karakter |

Spasi di awal dan akhir otomatis dihapus.

```bash
curl -X POST "{{BASE_URL}}/articles/tips-lari-pagi-untuk-pemula/comments" \
  -H "Content-Type: application/json" \
  -d '{"name": "Ngumar", "content": "Tipsnya bermanfaat!"}'
```

**Response `201 Created`:**

```json
{
  "success": true,
  "message": "Komentar berhasil dikirim",
  "data": {
    "id": 11,
    "name": "Ngumar",
    "content": "Tipsnya bermanfaat!",
    "created_at": "2026-10-11T08:00:00.000000+00:00"
  }
}
```

**Error:**

| Code | Kondisi |
|---|---|
| `400` | Body bukan JSON object yang valid |
| `404` | Artikel tidak ditemukan atau masih draft |
| `422` | `name` atau `content` tidak memenuhi aturan |

```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "name": "name wajib diisi, 2-50 karakter",
    "content": "content wajib diisi, 3-500 karakter"
  }
}
```

---

## 8. Endpoint Admin

Semua endpoint di bagian ini wajib menyertakan header:

```
x-api-key: <ADMIN_API_KEY>
Content-Type: application/json
```

### 8.1 Buat Artikel

```
POST /articles
```

**Body:**

| Field | Tipe | Wajib | Aturan / Default |
|---|---|---|---|
| `title` | string | ✅ | 5–200 karakter |
| `content` | string | ✅ | Minimal 20 karakter |
| `category_id` | integer | ✅ | ID kategori yang ada |
| `author_id` | integer | ✅ | ID penulis yang ada |
| `summary` | string \| null | – | – |
| `thumbnail_url` | string \| null | – | – |
| `slug` | string | – | Otomatis dibuat dari `title` jika tidak diisi. Selalu dinormalkan (huruf kecil, spasi menjadi `-`) |
| `tags` | string[] | – | Default `[]`. Dinormalkan seperti slug, duplikat dihapus |
| `is_featured` | boolean | – | Default `false` |
| `is_breaking` | boolean | – | Default `false` |
| `status` | string | – | `published` (default) atau `draft` |

```bash
curl -X POST "{{BASE_URL}}/articles" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <ADMIN_API_KEY>" \
  -d '{
    "title": "Belajar REST API dengan Supabase",
    "summary": "Panduan singkat membuat REST API untuk latihan.",
    "content": "Supabase menyediakan database PostgreSQL dan Edge Function.\n\nDengan keduanya, kita bisa membuat REST API lengkap.",
    "thumbnail_url": "https://picsum.photos/seed/rest-api-supabase/800/450",
    "category_id": 1,
    "author_id": 1,
    "tags": ["Supabase", "REST API", "latihan"],
    "is_featured": false
  }'
```

**Response `201 Created`:** `data` berisi Article (versi detail). Pada contoh di atas, slug otomatis menjadi `belajar-rest-api-dengan-supabase` dan tags menjadi `["supabase", "rest-api", "latihan"]`.

```json
{
  "success": true,
  "message": "Artikel berhasil dibuat",
  "data": {
    "id": 18,
    "title": "Belajar REST API dengan Supabase",
    "slug": "belajar-rest-api-dengan-supabase",
    "tags": ["supabase", "rest-api", "latihan"],
    "status": "published",
    "views": 0,
    "...": "..."
  }
}
```

**Error:**

| Code | Kondisi |
|---|---|
| `400` | Body bukan JSON object yang valid |
| `401` | `x-api-key` salah atau tidak ada |
| `409` | `slug` sudah dipakai artikel lain |
| `422` | Validasi gagal, atau `category_id` / `author_id` tidak ditemukan |

```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "title": "title wajib diisi, 5-200 karakter",
    "category_id": "category_id wajib berupa angka bulat positif"
  }
}
```

---

### 8.2 Ubah Artikel

```
PUT /articles/{id}
```

| Parameter | Lokasi | Tipe | Keterangan |
|---|---|---|---|
| `id` | path | integer | ID artikel (bukan slug) |

**Body:** sama seperti [Buat Artikel](#81-buat-artikel), tetapi **semua field opsional**. Cukup kirim field yang ingin diubah. Aturan validasi tetap berlaku untuk field yang dikirim.

> Mengubah `title` **tidak** mengubah `slug` secara otomatis. Kirim `slug` jika ingin menggantinya.
> `updated_at` diperbarui otomatis.

```bash
curl -X PUT "{{BASE_URL}}/articles/18" \
  -H "Content-Type: application/json" \
  -H "x-api-key: <ADMIN_API_KEY>" \
  -d '{"is_featured": true, "tags": ["supabase", "flutter"]}'
```

**Response `200 OK`:** `data` berisi Article (versi detail) setelah diubah, dengan `message: "Artikel berhasil diperbarui"`.

**Error:**

| Code | Kondisi |
|---|---|
| `400` | `id` bukan angka, atau body bukan JSON object |
| `401` | `x-api-key` salah atau tidak ada |
| `404` | Artikel tidak ditemukan |
| `409` | `slug` baru sudah dipakai |
| `422` | Validasi gagal, atau body tidak berisi field yang bisa diubah (`Tidak ada field yang diubah`) |

---

### 8.3 Hapus Artikel

```
DELETE /articles/{id}
```

Komentar milik artikel ikut terhapus.

```bash
curl -X DELETE "{{BASE_URL}}/articles/18" \
  -H "x-api-key: <ADMIN_API_KEY>"
```

**Response `200 OK`:**

```json
{
  "success": true,
  "message": "Artikel berhasil dihapus",
  "data": { "id": 18, "title": "Belajar REST API dengan Supabase" }
}
```

**Error:** `400` (id bukan angka), `401`, `404` (`Artikel tidak ditemukan`)

---

### 8.4 Hapus Komentar

```
DELETE /comments/{id}
```

```bash
curl -X DELETE "{{BASE_URL}}/comments/11" \
  -H "x-api-key: <ADMIN_API_KEY>"
```

**Response `200 OK`:**

```json
{
  "success": true,
  "message": "Komentar berhasil dihapus",
  "data": { "id": 11 }
}
```

**Error:** `400` (id bukan angka), `401`, `404` (`Komentar tidak ditemukan`)

---

## 9. Data Dummy

Data berikut tersedia setelah `02_seed.sql` dijalankan. Semua nama, tokoh, dan peristiwa bersifat **fiktif**.

> ID di bawah berlaku jika seed dijalankan pada tabel yang baru dibuat. Jika tabel pernah diisi lalu dikosongkan, ID bisa berbeda. Gunakan `GET /categories` dan `GET /authors` untuk memastikan.

### Kategori

| id | name | slug | Jumlah artikel |
|---|---|---|---|
| 1 | Teknologi | `teknologi` | 4 |
| 2 | Olahraga | `olahraga` | 3 |
| 3 | Ekonomi | `ekonomi` | 3 |
| 4 | Hiburan | `hiburan` | 2 |
| 5 | Kesehatan | `kesehatan` | 2 |
| 6 | Otomotif | `otomotif` | 2 (+1 draft) |

### Penulis

| id | name | slug |
|---|---|---|
| 1 | Rina Pratiwi | `rina-pratiwi` |
| 2 | Budi Santoso | `budi-santoso` |
| 3 | Sari Wulandari | `sari-wulandari` |
| 4 | Andi Firmansyah | `andi-firmansyah` |

### Artikel

| id | slug | Kategori | Featured | Breaking |
|---|---|---|---|---|
| 1 | `startup-lokal-luncurkan-aplikasi-kasir-ai-umkm` | teknologi | ✅ | |
| 2 | `panduan-memilih-laptop-belajar-pemrograman` | teknologi | | |
| 3 | `komunitas-developer-yogyakarta-gelar-hackathon-48-jam` | teknologi | | |
| 4 | `uji-coba-internet-satelit-sekolah-terpencil` | teknologi | | ✅ |
| 5 | `garuda-muda-juara-liga-futsal-pelajar` | olahraga | ✅ | |
| 6 | `tips-lari-pagi-untuk-pemula` | olahraga | | |
| 7 | `turnamen-bulu-tangkis-antarkampus-64-tim` | olahraga | | |
| 8 | `harga-cabai-turun-menjelang-panen-raya` | ekonomi | | ✅ |
| 9 | `umkm-kuliner-beralih-ke-pembayaran-digital` | ekonomi | | |
| 10 | `lima-kebiasaan-mengatur-keuangan-bulanan` | ekonomi | | |
| 11 | `festival-musik-indie-pantai-selatan` | hiburan | ✅ | |
| 12 | `film-animasi-mahasiswa-masuk-nominasi-internasional` | hiburan | | |
| 13 | `pentingnya-minum-air-putih-saat-cuaca-panas` | kesehatan | | |
| 14 | `posyandu-digital-pantau-tumbuh-kembang-anak` | kesehatan | | |
| 15 | `tips-merawat-motor-matic-awet-irit` | otomotif | ✅ | |
| 16 | `bengkel-kendaraan-listrik-bermunculan` | otomotif | | |
| 17 | `draft-rencana-liputan-pameran-otomotif` | otomotif | *draft — tidak tampil di API publik* | |

Ditambah **10 komentar** yang tersebar di beberapa artikel.

Tag yang tersedia antara lain: `tips`, `umkm`, `pemrograman`, `startup`, `ai`, `futsal`, `motor`, `keuangan`, `musik`, `festival`, `internet`, `pendidikan`.

---

## 10. Catatan Penting

- **Artikel draft** tidak pernah muncul di endpoint `GET` mana pun, termasuk saat memakai `x-api-key`. Draft hanya bisa diubah atau dihapus lewat `PUT` / `DELETE /articles/{id}`. Untuk menerbitkan draft, kirim `PUT /articles/{id}` dengan body `{"status": "published"}`.
- **Waktu** dikembalikan dalam format ISO 8601 dengan zona waktu UTC (`+00:00`). Konversikan ke zona lokal (misalnya WIB) di sisi aplikasi.
- **Isi artikel** (`content`) memakai `\n\n` sebagai pemisah paragraf.
- **CORS** diizinkan dari semua origin (`*`), sehingga API juga bisa dipakai dari aplikasi web.
- **Gambar dummy** berasal dari `picsum.photos` (thumbnail) dan `ui-avatars.com` (avatar), sehingga membutuhkan koneksi internet untuk ditampilkan.
- Untuk memakai API dari aplikasi publik, **jangan** menyertakan `ADMIN_API_KEY` di dalam aplikasi.
