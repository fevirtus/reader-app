#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env.mobile"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE"
  echo "Create it from .env.mobile.example"
  exit 1
fi

get_env() {
  local key="$1"
  awk -F'=' -v k="$key" '$1==k{print substr($0, index($0,$2)); exit}' "$ENV_FILE" | sed 's/^"//; s/"$//'
}

BASE_URL="$(get_env BASE_URL)"
GOOGLE_SERVER_CLIENT_ID="$(get_env GOOGLE_SERVER_CLIENT_ID)"
GOOGLE_CLIENT_ID="$(get_env GOOGLE_CLIENT_ID)"

if [[ -z "$BASE_URL" ]]; then
  echo "BASE_URL is required in $ENV_FILE"
  exit 1
fi

if [[ -z "$GOOGLE_SERVER_CLIENT_ID" ]]; then
  echo "GOOGLE_SERVER_CLIENT_ID is required in $ENV_FILE"
  exit 1
fi

cd "$ROOT_DIR"

if [[ -n "$GOOGLE_CLIENT_ID" ]]; then
  flutter run \
    --dart-define=BASE_URL="$BASE_URL" \
    --dart-define=GOOGLE_SERVER_CLIENT_ID="$GOOGLE_SERVER_CLIENT_ID" \
    --dart-define=GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID" \
    "$@"
else
  flutter run \
    --dart-define=BASE_URL="$BASE_URL" \
    --dart-define=GOOGLE_SERVER_CLIENT_ID="$GOOGLE_SERVER_CLIENT_ID" \
    "$@"
fi
