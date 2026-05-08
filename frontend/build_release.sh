#!/bin/bash
set -e

echo "=== Learno Release APK Builder ==="
echo

if [ ! -f "pubspec.yaml" ]; then
    echo "ERROR: Run this script from the flutter_tested directory."
    echo "Usage: cd flutter_tested && bash build_release.sh"
    exit 1
fi

read -rp "Enter backend URL (e.g. https://your-app.railway.app): " API_URL
if [ -z "$API_URL" ]; then
    API_URL="https://your-backend-url.com"
    echo "Using placeholder URL. Update with real URL before distributing."
fi

echo
echo "Cleaning previous builds..."
flutter clean

echo
echo "Getting dependencies..."
flutter pub get

echo
echo "Generating localization files..."
flutter gen-l10n

echo
echo "[1/2] Building release APK..."
flutter build apk --release --dart-define=API_BASE_URL="$API_URL"

echo
echo "[2/2] Building Android App Bundle (Play Store)..."
flutter build appbundle --release --dart-define=API_BASE_URL="$API_URL"

echo
echo "=== BUILD COMPLETE ==="
echo "APK:    build/app/outputs/flutter-apk/app-release.apk"
echo "Bundle: build/app/outputs/bundle/release/app-release.aab"
echo
echo "Share the APK for direct distribution / testing."
echo "Upload the .aab to Google Play Console."
