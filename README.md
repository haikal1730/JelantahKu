# JelantahKu – Milestone 5 (Supabase)

Versi ini menggunakan **Supabase sebagai backend utama** untuk Authentication dan PostgreSQL Database. Firebase hanya opsional untuk FCM push notification.

## Stack
- Flutter + Riverpod
- Supabase Auth: Email/Password + Google OAuth
- Supabase Postgres + RLS
- Supabase RPC untuk transaksi atomic/idempotent
- Supabase Realtime untuk perubahan data
- SharedPreferences + Secure Storage untuk offline-first/cache/session
- Midtrans Sandbox melalui backend Express
- FCM opsional untuk push notification

## 1. Buat project Supabase

Buat project di Supabase Dashboard. Setelah project dibuat:

1. Ambil **Project URL** dan **Publishable Key** dari Connect/API.
2. Buka SQL Editor.
3. Jalankan `supabase/migrations/202609090001_jelantahku.sql`.
4. Authentication → Providers → aktifkan Email.
5. Authentication → Providers → aktifkan Google dan masukkan OAuth Client ID/Secret dari Google Cloud.
6. Authentication → URL Configuration → tambahkan redirect:
   `io.supabase.jelantahku://login-callback/`
7. Untuk web, tambahkan URL web aplikasi sebagai Redirect URL.

> Jangan pernah memasukkan `service_role` key ke Flutter. Flutter hanya memakai Publishable Key.

## 2. Jalankan Flutter

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Atau gunakan `.env.supabase.example` sebagai referensi variabel.

## 3. Fitur Supabase yang sudah terhubung

### Authentication
- Register Email/Password
- Login Email/Password
- Google OAuth
- Restore session
- Logout
- Profile otomatis dibuat melalui trigger `auth.users → profiles`

### Database
Tabel:
- `profiles`
- `transactions`
- `payments`
- `notification_tokens`

RLS memastikan user hanya dapat membaca/mengelola data miliknya sendiri.

### Transaksi & saldo
Aplikasi memanggil RPC:
`public.create_transaction(...)`

RPC melakukan:
- validasi user berdasarkan `auth.uid()`
- idempotency berdasarkan transaction ID
- update saldo secara atomic
- menolak withdrawal jika saldo tidak cukup
- insert transaksi dalam transaksi database yang sama

### Realtime
`profiles` dan `transactions` sudah dimasukkan ke publication `supabase_realtime`.
Aplikasi dapat menambahkan subscription menggunakan Supabase Realtime jika diperlukan untuk live balance/history.

## 4. Google OAuth Android/iOS

Android sudah memiliki deep-link:
`io.supabase.jelantahku://login-callback`

iOS juga sudah memiliki URL scheme yang sama.

Di Google Cloud OAuth Client, gunakan callback URL Supabase yang diberikan dashboard sebagai **Authorized redirect URI**. Jangan menebak URL callback tersebut.

## 5. Push Notification

Auth/database tidak membutuhkan Firebase.
Jika FCM dibutuhkan, Firebase Messaging tetap tersedia secara opsional. Token FCM setelah login disimpan ke:
`notification_tokens(user_id, token, platform)`.

Untuk mengirim push dari server, gunakan Supabase Edge Function/backend dengan secret FCM service account. Jangan menyimpan credential FCM di Flutter.

## 6. Payment Gateway

Backend `backend/server.js` sekarang menggunakan Supabase untuk validasi JWT dan penyimpanan pembayaran.

```bash
cd backend
npm install
cp .env.example .env
npm start
```

`.env`:
```env
PORT=8080
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_SERVER_KEY=YOUR_MIDTRANS_SERVER_KEY
```

Flutter:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=PAYMENT_MODE=real \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`SUPABASE_SERVICE_ROLE_KEY` hanya boleh berada di backend/server.

## 7. Demo tanpa Supabase

Project masih menyediakan fallback demo:
```bash
flutter run --dart-define=USE_SUPABASE=false
```

## 8. Struktur penting

```text
lib/
├── core/
│   ├── config/app_config.dart
│   └── supabase/supabase_client.dart
├── features/auth/
│   ├── data/auth_service.dart
│   └── presentation/providers/auth_provider.dart
├── features/warga/
│   └── data/datasources/supabase_transaction_datasource.dart
└── main.dart

supabase/
├── migrations/202609090001_jelantahku.sql
├── config.toml
└── README.md

backend/
├── server.js
├── package.json
└── .env.example
```

## Referensi resmi
Supabase Flutter menggunakan `supabase_flutter` v2, Publishable Key untuk client, RLS untuk keamanan data, dan Realtime/Postgres Changes untuk sinkronisasi perubahan database.

## Full Midtrans Sandbox Flow — Milestone 5

Alur pembayaran Premium sekarang:

`Berlangganan → Backend membuat Snap transaction → Midtrans Sandbox → Webhook → Supabase payments → profiles Premium → Riwayat pembayaran`

### 1. Midtrans Sandbox

Di Midtrans MAP, gunakan environment **Sandbox** dan ambil **Server Key Sandbox**. Jangan masukkan Server Key ke Flutter. Server Key harus berada di backend.

Backend `.env`:

```env
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxx
```

### 2. Supabase

Jalankan migration:

```text
supabase/migrations/202609090001_jelantahku.sql
```

Pastikan tabel `profiles` dan `payments` aktif dengan RLS. Backend menggunakan `SUPABASE_SERVICE_ROLE_KEY`; Flutter hanya menggunakan Publishable Key.

### 3. Jalankan backend

```bash
cd backend
npm install
cp .env.example .env
npm start
```

Health check:

```text
GET http://localhost:8080/health
```

### 4. Webhook Midtrans

Backend endpoint:

```text
POST https://DOMAIN-PUBLIC-KAMU/payments/midtrans/webhook
```

Masukkan URL tersebut di Midtrans Sandbox pada pengaturan **Payment Notification URL**.

Untuk pengujian lokal, gunakan tunnel HTTPS seperti ngrok/Cloudflare Tunnel sehingga Midtrans dapat mengakses komputer developer. Jangan memakai URL `localhost` pada dashboard Midtrans.

Webhook adalah sumber kebenaran status pembayaran. Backend memvalidasi notifikasi menggunakan Midtrans SDK, menyimpan status di `payments`, lalu mengaktifkan Premium di `profiles` ketika status menjadi paid.

### 5. Jalankan Flutter

Android Emulator:

```bash
flutter pub get
flutter run \
  --dart-define=USE_SUPABASE=true \
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=PAYMENT_MODE=real \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Jika backend memakai URL tunnel:

```bash
--dart-define=API_BASE_URL=https://YOUR-TUNNEL-DOMAIN
```

### 6. Test happy flow Sandbox

Login sebagai user Supabase → buka **Premium** → tekan **Berlangganan Rp25.000** → halaman Snap Sandbox terbuka → pilih Credit Card → gunakan kartu test Midtrans:

```text
Card: 4811 1111 1111 1114
CVV: 123
Expiry: bulan apa saja + tahun mendatang
OTP/3DS: 112233
```

Setelah transaksi berhasil, Midtrans mengirim webhook. Backend mengubah `payments.status` menjadi `paid`, lalu mengaktifkan:

```text
profiles.subscription_active = true
profiles.subscription_expires_at = +1 bulan
```

Aplikasi melakukan polling status order dan menampilkan Premium aktif. Riwayat pembayaran mengambil data langsung dari tabel `payments` melalui Supabase RLS.

### 7. Test failure

Gunakan kartu Sandbox Midtrans yang didokumentasikan sebagai kartu denied untuk memastikan alur `failed` tidak mengaktifkan Premium.

### 8. Catatan penting

Jangan pernah melakukan pembayaran Sandbox dengan uang/kartu bank sungguhan. Midtrans menyediakan simulator/credential khusus Sandbox. Lihat dokumentasi resmi Midtrans untuk daftar metode dan credential test terbaru.

## Milestone 6 — Release

Release Android memakai R8/ProGuard dan compile-time configuration melalui `--dart-define`.
Jangan commit `.env`, `android/key.properties`, atau private release keystore.

Build lokal:

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define-from-file=env.production.json
```

Lihat `docs/release/` dan `MILESTONE_6_FINAL_CHECKLIST.md` untuk release checklist.
