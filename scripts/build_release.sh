#!/usr/bin/env bash
set -euo pipefail
ENV_FILE="${1:-env.production.json}"
BUILD_NUMBER="${2:-2}"
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define-from-file="$ENV_FILE" --build-number="$BUILD_NUMBER"
echo "Signed AAB should be at build/app/outputs/bundle/release/app-release.aab"
