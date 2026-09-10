# Auth Email Error Fix

Perbaikan pada `lib/features/auth/data/auth_service.dart`:

- `@warga.com` dan domain valid lain tetap diterima oleh validator Flutter.
- Error Supabase yang mengandung kata `email` tidak lagi otomatis diubah menjadi `Format email tidak valid.`
- Error seperti rate limit, registrasi dinonaktifkan, email sudah terdaftar, dan login gagal mendapat pesan yang lebih jelas.
- Error Supabase lain ditampilkan sebagai `Supabase: ...` supaya penyebab sebenarnya terlihat.

Setelah unzip:

```bash
flutter pub get
flutter run -d chrome
```

Jika masih muncul error Supabase, kirim screenshot pesan error terbaru. Jangan kirim password atau service-role key.
