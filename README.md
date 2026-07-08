# reader-app

Flutter mobile app for reading novels, synced with the existing web platform.

## Scope


- Full end-user feature parity with the current web app.
- Excludes all moderator/admin workflows.

## Implemented vs planned

Đã có trong code (theo `lib/features`): đăng nhập Google, home/browse, genres, tìm kiếm, chi tiết truyện + danh sách chương, reader (kèm TTS), bookshelf, bookmark/progress, bình luận, splash/settings.

Còn thiếu hoặc mới dạng placeholder so với web: gợi ý tìm kiếm (`/api/truyen/suggest`), đánh giá truyện (`/api/truyen/{id}/rate`), đồng bộ settings và đề cử người dùng (`/api/user/settings`, `/api/user/recommendations`). Chi tiết parity xem `FEATURES.md` và `CROSS_REPO_ENDPOINT_MATRIX.md`.

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

Default `BASE_URL` khi **không** truyền `--dart-define` (xem `lib/core/config/app_config.dart`):

- Android (native, không phải web build): `https://reader-api.fevirtus.dev`
- Các nền tảng khác (iOS, desktop, web build, v.v.): `http://localhost:8000`

Để dev local trên Android emulator, luôn set rõ qua `--dart-define` hoặc file `.env.mobile` + `scripts/flutter_run_with_env.sh`, ví dụ `http://10.0.2.2:8000`.

Override trực tiếp:

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


Noted:

Với MIUI:
Cần hướng dẫn user (không thể fix bằng code)
MIUI AutoStart: User phải vào Cài đặt → Ứng dụng → [app] → AutoStart và bật thủ công
MIUI Battery Optimization: User phải vào Cài đặt → Pin → Ứng dụng tiêu hao pin → [app] → chọn "Không hạn chế" (permission REQUEST_IGNORE_BATTERY_OPTIMIZATIONS đã có trong Manifest để trigger dialog, nhưng user vẫn phải accept)
