# jelantah_ku

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Milestone 4 – Persistent Data, Offline-First, & Local Cache

Implementasi Milestone 4 menggunakan:
- SharedPreferences untuk cache transaksi, saldo, dan antrean sinkronisasi.
- FlutterSecureStorage untuk session user dan status subscription.
- connectivity_plus untuk mendeteksi perubahan koneksi.
- Offline-First Repository: membaca cache ketika offline dan menyimpan transaksi baru ke pending queue.
- Automatic Sync: transaksi pending dikirim kembali ketika koneksi internet terdeteksi.

Alur utama:
`Remote -> Local Cache -> UI` saat online, dan `Local Cache -> UI` saat offline.
Transaksi yang dibuat saat offline masuk ke `pending_sync` dan akan disinkronkan otomatis ketika online.
