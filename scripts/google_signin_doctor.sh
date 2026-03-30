#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_GRADLE="$ROOT_DIR/android/app/build.gradle.kts"
GOOGLE_SERVICES="$ROOT_DIR/android/app/google-services.json"
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

echo "== Google Sign-In Doctor (Android) =="
echo "Project: $ROOT_DIR"

if [[ -f "$APP_GRADLE" ]]; then
  PKG=$(grep -E 'applicationId\s*=\s*"' "$APP_GRADLE" | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')
  echo "Package name: ${PKG:-<not-found>}"
else
  echo "ERROR: Missing $APP_GRADLE"
fi

if [[ -f "$GOOGLE_SERVICES" ]]; then
  echo "google-services.json: FOUND ($GOOGLE_SERVICES)"
  if grep -q '"project_info"' "$GOOGLE_SERVICES"; then
    echo "google-services.json format: OK"
  else
    echo "google-services.json format: INVALID (this does not look like Firebase Android config)"
  fi
else
  echo "google-services.json: MISSING ($GOOGLE_SERVICES)"
fi

CLIENT_SECRET_FILE=$(ls "$ROOT_DIR"/android/app/client_secret_*.json 2>/dev/null | head -n1 || true)
if [[ -n "$CLIENT_SECRET_FILE" ]]; then
  echo "Found OAuth client secret file: $(basename "$CLIENT_SECRET_FILE")"
  echo "NOTE: This file is NOT a replacement for google-services.json on Android."
fi

if [[ -f "$DEBUG_KEYSTORE" ]]; then
  echo "\nDebug keystore fingerprints:"
  keytool -list -v -alias androiddebugkey -keystore "$DEBUG_KEYSTORE" -storepass android -keypass android \
    | grep -E 'SHA1:|SHA256:' || true
else
  echo "\nDebug keystore: MISSING ($DEBUG_KEYSTORE)"
fi

echo "\nChecklist for ApiException: 10"
echo "1) Create Android app in Firebase with exact package name above."
echo "2) Add BOTH SHA1 and SHA256 shown above to Firebase Android app settings."
echo "3) Download new google-services.json and place it at android/app/google-services.json."
echo "4) Run app again (full restart, not hot reload)."
