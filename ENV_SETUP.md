# Konfigurasi environment

## Flutter
File `.env` di root project sudah dibaca otomatis saat aplikasi start.
Ke depannya cukup jalankan:

```bash
flutter run
```

Tidak perlu lagi `--dart-define-from-file=.env`.

## Backend
Simpan konfigurasi server di `backend/.env` berdasarkan `backend/.env.example`.
Jangan pernah memasukkan Supabase service-role key ke Flutter atau ke file yang dibagikan publik.
