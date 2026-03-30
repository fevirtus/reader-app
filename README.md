# reader-app

Flutter mobile app for reading novels, synced with the existing web platform.

## Scope

- Full end-user feature parity with the current web app.
- Excludes all moderator/admin workflows.

## Planned Feature Set

- Google login and authenticated user session.
- Home feed, hot boards, and recommendations.
- Search with suggestions, genre, status, and sort filters.
- Novel detail with chapter list and series metadata.
- Reader with TOC, reading preferences, and progress sync.
- Bookshelf tabs: Dang doc, Danh dau, Da doc, De cu.
- Comments, ratings, and user recommendations.
- Native TTS and offline reading support.

## Architecture

- `lib/core`: app-wide config, network, storage, and theme.
- `lib/features`: feature modules split by domain.
- `lib/shared`: shared UI widgets.

## Run

```bash
flutter pub get
flutter run
```

Run with env file (recommended for local dev):

1. Create local env from sample:

```bash
cp .env.mobile.example .env.mobile
```

1. Start app using env values:

```bash
bash scripts/flutter_run_with_env.sh
```

This script reads `.env.mobile` and automatically passes:

- `BASE_URL`
- `GOOGLE_SERVER_CLIENT_ID`
- optional `GOOGLE_CLIENT_ID`

Default `BASE_URL` behavior:

- Android emulator: `http://10.0.2.2:8000`
- Others (iOS simulator, desktop, web): `http://localhost:8000`

If needed, you can still override explicitly:

```bash
flutter run --dart-define=BASE_URL=http://localhost:8000
```

For Android emulator, use:

```bash
flutter run --dart-define=BASE_URL=http://10.0.2.2:8000
```

For a physical device in dev, use your computer LAN IP (same Wi-Fi):

```bash
flutter run --dart-define=BASE_URL=http://<YOUR_LAN_IP>:8000
```

Important notes for physical devices:

- Use the Wi-Fi LAN IP from `en0` (example: `10.17.2.62`).
- Do NOT use VPN/tunnel IPs from `utun` (example: `100.x.x.x`) unless your phone is connected to the same VPN.
- Keep phone and computer on the same Wi-Fi network.

Android over USB (stable local tunnel):

```bash
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=BASE_URL=http://127.0.0.1:8000
```

## Google Sign-In (Android)

If you see `PlatformException ... ApiException: 10`, it is usually an OAuth config mismatch.

Checklist:

- `android/app/google-services.json` must exist and match package name `com.example.reader_app`.
- Add SHA-1 and SHA-256 fingerprints of your debug keystore to Firebase Android app settings.
- Ensure OAuth client IDs are created after adding SHA fingerprints.
- Run with server/web client id for backend token verification:

```bash
# Bước 1: Khởi động emulator
flutter emulators --launch Pixel_8_API_35
flutter run
```

```bash
flutter run \
  --dart-define=BASE_URL=http://127.0.0.1:8000 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<YOUR_WEB_CLIENT_ID>.apps.googleusercontent.com
```

Optional (iOS/web):

```bash
--dart-define=GOOGLE_CLIENT_ID=<YOUR_IOS_OR_WEB_CLIENT_ID>.apps.googleusercontent.com
```
