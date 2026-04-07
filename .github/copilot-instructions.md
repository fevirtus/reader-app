# Project Guidelines

## Code Style
- Dùng Dart/Flutter theo lint mặc định trong `analysis_options.yaml` (flutter_lints).
- Tổ chức theo feature-first: code mới đặt đúng module trong `lib/features/**`, phần dùng chung đặt ở `lib/core/**` hoặc `lib/shared/**`.
- Tránh logic nghiệp vụ trong widget build; chuyển sang provider/notifier.
- Giữ naming nhất quán: file snake_case, class PascalCase, provider rõ nghĩa theo tính năng.

## Architecture
- `lib/main.dart`: bootstrap app + ProviderScope.
- `lib/app/`: app shell, router và route names.
- `lib/core/`: config, network, storage, theme, models dùng toàn app.
- `lib/features/`: từng domain (auth, home, search, novel, reader, bookshelf, comments, profile, settings...).
- `lib/shared/`: widgets dùng chung.
- State management chính: Riverpod; networking: Dio; routing: go_router.

## Build and Test
- Cài dependencies: `flutter pub get`
- Chạy app: `flutter run`
- Khuyến nghị local: `bash scripts/flutter_run_with_env.sh`
- Phân tích lint/static: `flutter analyze`
- Chạy test hiện có: `flutter test`

## Conventions
- Cấu hình API base URL lấy từ AppConfig/env; không hardcode URL trực tiếp trong feature code.
- Token/session xử lý qua tầng storage/network ở `lib/core`, tránh duplicate auth flow trong từng feature.
- Khi thêm màn hình mới, cập nhật router tập trung ở `lib/app/router/app_router.dart`.
- Ưu tiên tái sử dụng models trong `lib/core/models` thay vì tạo kiểu dữ liệu rời rạc.

## Pitfalls
- Android emulator phải dùng `10.0.2.2` để gọi localhost backend; iOS simulator/web thường dùng `localhost`.
- Google Sign-In Android dễ lỗi `ApiException: 10` nếu cấu hình SHA/OAuth client không khớp.
- Thiếu `.env.mobile` hoặc thiếu `GOOGLE_SERVER_CLIENT_ID` có thể làm luồng đăng nhập thất bại.
- Thiết bị thật cần LAN IP đúng mạng nội bộ; không dùng VPN IP nếu điện thoại không cùng tunnel.

## Key References
- Tổng quan setup + Google Sign-In: `README.md`
- Lint rules: `analysis_options.yaml`
- App config/env: `lib/core/config/app_config.dart`
- API client + interceptor: `lib/core/network/api_client.dart`
- Router trung tâm: `lib/app/router/app_router.dart`
- Script chạy với env: `scripts/flutter_run_with_env.sh`
