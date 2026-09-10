# JelantahKu — Milestone 6 Final Checklist

## 1. Security
- [x] `.env` tidak lagi menjadi Flutter asset.
- [x] Client configuration menggunakan compile-time `--dart-define`.
- [x] `.env` dan backend `.env` dihapus dari release source package.
- [x] R8/ProGuard diaktifkan pada release build.
- [x] Release signing membaca `android/key.properties`, bukan password hard-coded.

## 2. CI/CD
- [x] Architectural deployment prompt tersedia.
- [x] GitHub Actions workflow tersedia.
- [x] Analyze → test → signed AAB → artifact sudah dirancang otomatis.

## 3. Signed AAB
- [x] Signing configuration sudah dipasang.
- [ ] AAB harus dibuild pada mesin yang memiliki Flutter + Android SDK dan release keystore.

## 4. Release files
- [x] Privacy Policy draft tersedia.
- [x] Data Safety Declaration draft tersedia.
- [x] Internal/Beta Testing checklist tersedia.

## 5. Final demo
- [ ] Upload AAB ke Internal Testing/Firebase App Distribution.
- [ ] Install pada perangkat tester.
- [ ] Rekam/screenshot bukti pengujian.

> Catatan: build AAB tidak dipalsukan. Environment ini tidak memiliki Flutter/Android SDK yang diperlukan untuk menghasilkan binary Android yang valid.
