#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
KEY_PROPERTIES="$ANDROID_DIR/key.properties"
APK_PATH="${1:-$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk}"

echo "== Android Release Signing Doctor =="
echo "Project: $ROOT_DIR"

echo "\n[1] Checking key.properties"
if [[ -f "$KEY_PROPERTIES" ]]; then
  echo "FOUND: $KEY_PROPERTIES"
  sed 's/password=.*/password=***HIDDEN***/' "$KEY_PROPERTIES"
else
  echo "MISSING: $KEY_PROPERTIES"
  echo "Create this file for release signing."
fi

echo "\n[2] Checking keystore from key.properties"
if [[ -f "$KEY_PROPERTIES" ]]; then
  STORE_FILE_REL="$(grep '^storeFile=' "$KEY_PROPERTIES" | head -n1 | cut -d'=' -f2-)"
  STORE_FILE="$ANDROID_DIR/$STORE_FILE_REL"
  KEY_ALIAS="$(grep '^keyAlias=' "$KEY_PROPERTIES" | head -n1 | cut -d'=' -f2-)"
  STORE_PASS="$(grep '^storePassword=' "$KEY_PROPERTIES" | head -n1 | cut -d'=' -f2-)"
  KEY_PASS="$(grep '^keyPassword=' "$KEY_PROPERTIES" | head -n1 | cut -d'=' -f2-)"

  if [[ -f "$STORE_FILE" ]]; then
    echo "FOUND keystore: $STORE_FILE"
    echo "Alias: $KEY_ALIAS"
    echo "Fingerprints:"
    keytool -list -v -keystore "$STORE_FILE" -alias "$KEY_ALIAS" -storepass "$STORE_PASS" -keypass "$KEY_PASS" | grep -E 'SHA1:|SHA256:'
  else
    echo "Keystore not found: $STORE_FILE"
  fi
fi

echo "\n[3] Checking APK signature"
if [[ -f "$APK_PATH" ]]; then
  echo "APK: $APK_PATH"
  if command -v apksigner >/dev/null 2>&1; then
    apksigner verify --print-certs "$APK_PATH"
  else
    echo "apksigner not found in PATH."
    echo "Try: \$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs $APK_PATH"
  fi
else
  echo "APK not found at: $APK_PATH"
fi

echo "\n[4] CI secrets required"
echo "- TOKEN"
echo "- BASE_URL"
echo "- GOOGLE_SERVER_CLIENT_ID"
echo "- ANDROID_KEYSTORE_BASE64"
echo "- ANDROID_KEYSTORE_PASSWORD"
echo "- ANDROID_KEY_ALIAS"
echo "- ANDROID_KEY_PASSWORD"
echo "- EXPECTED_ANDROID_SHA1 (optional but recommended)"
