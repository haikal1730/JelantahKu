# JelantahKu — cara menjalankan

Versi ini sudah disiapkan agar konfigurasi Supabase dibaca otomatis dari `.env`.

## Jalankan

```bash
flutter run
```

Tidak perlu `--dart-define` dan tidak perlu mengedit `app_config.dart`.

## Role

Role dibaca dari `public.profiles.role` di Supabase:
- `warga`
- `admin`
- `owner`

Tidak ada lagi fallback ke akun DEMO saat Supabase aktif. Jika `.env` tidak terbaca, aplikasi akan tetap di halaman login dan menampilkan pesan konfigurasi, bukan masuk sebagai Warga DEMO.

## Logout

Warga, Admin, dan Owner memiliki tombol **Keluar** di halaman Profil dan drawer. Logout menghapus sesi Supabase lalu kembali ke halaman login.

## Catatan

`SUPABASE_PUBLISHABLE_KEY` aman digunakan di aplikasi Flutter. Jangan pernah memasukkan `SUPABASE_SERVICE_ROLE_KEY` ke Flutter atau `.env` Flutter.
