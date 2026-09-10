# Architectural Prompt for Deployment — JelantahKu

Buat pipeline CI/CD untuk aplikasi Flutter JelantahKu.

Persyaratan:
1. Trigger pada push branch utama, pull request, dan manual dispatch.
2. Gunakan Java 17 dan Flutter stable.
3. Jalankan `flutter pub get`, `flutter analyze`, dan `flutter test`.
4. Build Android App Bundle release menggunakan R8/ProGuard.
5. Gunakan GitHub Actions Secrets untuk seluruh credential build.
6. Jangan mencetak secret ke log.
7. Jangan commit `.env`, `android/key.properties`, atau private signing keystore.
8. Decode keystore hanya selama job release.
9. Jalankan `flutter build appbundle --release` dengan `--dart-define`.
10. Upload `app-release.aab` sebagai workflow artifact.
11. Pipeline harus gagal bila analyze, test, atau build gagal.
12. Gunakan least privilege dan hapus file keystore sementara setelah job selesai bila diperlukan.
