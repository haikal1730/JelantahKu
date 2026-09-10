param(
  [string]$EnvFile = "env.production.json",
  [int]$BuildNumber = 2
)
$ErrorActionPreference = "Stop"
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define-from-file=$EnvFile --build-number=$BuildNumber
Write-Host "Signed AAB should be at build/app/outputs/bundle/release/app-release.aab"
