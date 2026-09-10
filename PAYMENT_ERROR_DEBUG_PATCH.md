# Payment Error Debug Patch

Patch ini membuat error pembayaran menampilkan detail response backend.

File yang diubah:
- `lib/core/network/api_client.dart`
- `lib/features/payment/presentation/screens/subscription_screen.dart`

Setelah mengganti file, jalankan:

```bash
flutter pub get
flutter run -d chrome
```

Backend tetap harus berjalan di port 8080 dan `API_BASE_URL=http://localhost:8080` untuk Chrome.
