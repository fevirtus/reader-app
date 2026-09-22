# Reader App

Ứng dụng Flutter cho người đọc trong bộ Reader, dùng chung backend `reader-api`
với web `reader`. Mục tiêu là đồng bộ các tính năng dành cho người đọc; quản trị
và import EPUB thuộc phạm vi web.

## Phạm vi hiện tại

- Đăng nhập Google; duyệt, tìm kiếm, xem thể loại và chi tiết truyện.
- Mục lục, đọc chương, rating, tủ sách đang đọc/đã đọc.
- Lưu tiến độ đọc local và gửi thông tin chương lên backend khi có kết nối.
- Tùy chỉnh giao diện đọc, đọc bằng TTS.
- Tải chương, quản lý tải xuống và đọc nội dung đã cache/tải khi offline.

Settings đọc hiện lưu local, chưa đồng bộ `/api/user/settings`.
Tìm kiếm dùng browse API, chưa tích hợp `/api/truyen/suggest`.
Vị trí cuộn lưu local; backend hiện lưu tiến độ theo chương, không lưu giá trị
`progress` mà app gửi. Không có hàng đợi phát lại tiến độ khi request thất bại.
Bình luận và đề cử không thuộc phạm vi hiện tại.

## Cấu trúc

- `lib/app/`: khởi tạo app và router.
- `lib/features/`: auth, home, search, genres, novel, reader, bookshelf, downloads,
  profile và settings.
- `lib/core/network/`: Dio và gắn Bearer token.
- `lib/core/storage/`: secure storage, SharedPreferences và database Drift/SQLite.
- `lib/core/repositories/`: dữ liệu cache cho truyện, chương, thể loại, tủ sách và tải xuống.
- `lib/core/download/`, `lib/core/connectivity/`: tải nội dung và theo dõi kết nối.
- `lib/shared/`: widget dùng chung.

App đổi Google ID token lấy JWT qua `POST /api/auth/mobile-login`, lưu token vào
secure storage và dùng `Authorization: Bearer ...` khi gọi API.

## Chạy local

Cần Flutter đi kèm Dart đáp ứng `pubspec.yaml` (hiện `^3.11.3`), SDK của nền tảng
chạy và backend đã có dữ liệu/schema.

```bash
flutter pub get
cp .env.mobile.example .env.mobile
```

Sửa `.env.mobile` cho môi trường của bạn:

```dotenv
BASE_URL=http://10.0.2.2:8000
GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_ID=
```

`GOOGLE_SERVER_CLIENT_ID` là OAuth web/server client ID dùng để lấy Google ID
token cho backend; backend phải cho phép client ID đó. `GOOGLE_CLIENT_ID` là tùy
chọn theo nền tảng.

```bash
bash scripts/flutter_run_with_env.sh
```

Chọn `BASE_URL` theo thiết bị:

- Android emulator: `http://10.0.2.2:8000`.
- Simulator/desktop chạy cùng máy API: `http://localhost:8000`.
- Thiết bị thật: địa chỉ LAN của máy API, hoặc địa chỉ mạng mà thiết bị truy cập được.
- Android qua USB: chạy `adb reverse tcp:8000 tcp:8000`, rồi dùng
  `http://127.0.0.1:8000`.

Nếu không truyền `BASE_URL`, Android native mặc định dùng
`https://reader-api.fevirtus.dev`, các nền tảng khác dùng `http://localhost:8000`.
Khi phát triển local nên đặt rõ URL. API chạy bằng service `api-local` của compose
mở cổng 8001 thay vì 8000.

## Kiểm tra và build

```bash
flutter analyze
flutter test
```

Sau khi thay đổi bảng Drift:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Các lệnh này là cách kiểm tra dự án, không phải xác nhận mọi nền tảng đã được
kiểm thử. Repo có scaffold iOS/desktop/web; cần kiểm tra riêng tính tương thích
storage, plugin và cấu hình đăng nhập trên từng nền tảng.

Hai workflow trong `.github/workflows/` build APK/AAB khi push tag `v*` hoặc chạy
thủ công. Chúng dùng Flutter 3.41.5 / Dart 3.11.3, Java 21 và Android SDK có sẵn
trên Ubuntu 24.04, cache Flutter/pub/Gradle và cài SDK 36 cùng NDK tương ứng.
`BASE_URL` mặc định là `https://reader-api.fevirtus.dev`; secret cùng tên có thể
ghi đè bằng một URL HTTPS khác. Google client ID lấy từ secrets như trước.

Để tạo file cho Google Play, chọn **Actions → Build Android AAB → Run workflow**:

- Có thể để trống `release_tag`: file vẫn được lưu trong **Artifacts** của lần
  chạy trong 14 ngày. Giải nén artifact và tải file `.aab` lên Play Console.
- `build_number` ghi đè Android `versionCode`; phải lớn hơn mã đã tải lên Play.
  Nếu để trống, dùng phần sau dấu `+` trong `pubspec.yaml`. Chạy lại workflow
  không tự tăng versionCode; `release_tag` cũng không thay đổi phiên bản ứng dụng.
- Khi có `release_tag`, workflow còn đính kèm file vào GitHub Release.
- Secrets ký bắt buộc: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_PASSWORD`. `ANDROID_KEY_ALIAS` có thể để trống để lấy alias đầu tiên.
- `EXPECTED_ANDROID_SHA1` (nếu đặt) phải là SHA-1 của **upload key** đã đăng ký
  trong Play Console, không phải app-signing key do Google dùng để phân phối app.

Workflow kiểm tra chữ ký trước khi lưu artifact và xóa file khóa sau khi chạy.
Workflow không tự upload hay phát hành ứng dụng lên Google Play.

## Chẩn đoán đăng nhập Android

Khi gặp `ApiException: 10`, kiểm tra package name trong
`android/app/build.gradle.kts`, cấu hình `google-services.json`, client ID và
fingerprint của đúng khóa ký debug/release:

```bash
bash scripts/google_signin_doctor.sh
bash scripts/release_signing_doctor.sh
```

## Tài liệu dùng chung

Các liên kết dưới đây giả định ba repo được checkout cạnh nhau:

- [Backend và cách chạy](../reader-api/README.md)
- [API contract hiện tại](../reader-api/CONTRACT.md)
- [Đối chiếu tính năng web/mobile](../reader-api/CROSS_REPO_ENDPOINT_MATRIX.md)

## Offline, đồng bộ và cập nhật bản tải

- Nội dung và mục lục của truyện đã tải được đọc từ snapshot local.
  Dùng **Tủ sách → Đã tải xuống → Cập nhật** để kiểm tra/tải bản mới.
  Nếu tải lỗi hoặc server sửa nội dung giữa chừng, bản cũ vẫn đọc được.
  Thử lại tái sử dụng các chương đã tải đúng checksum, không tải lại toàn bộ.
- Tiến độ, đánh dấu đã đọc và xóa khỏi tủ sách được lưu theo tài khoản trong
  SQLite cùng outbox. App gửi lại khi có mạng, mở lại app và định kỳ 30 giây
  khi app đang hoạt động. Không yêu cầu đồng bộ nền khi hệ điều hành đã dừng app.
- Không xóa thao tác chưa được API xác nhận. Khi API không truy cập được,
  banner báo thay đổi chưa đồng bộ. Cần đăng nhập lại nếu token thực sự hết hạn;
  lỗi mất mạng/5xx/403 không tự xóa phiên đăng nhập.
- Đổi tài khoản không gửi thao tác của tài khoản cũ bằng token của tài khoản mới.
  Bản tải là nội dung công khai dùng chung trên thiết bị; tiến độ/tủ sách tách riêng.
- Nâng cấp database giữ nguyên các chương đã tải. Cache bookmark và progress
  từ phiên bản cũ không có thông tin chủ tài khoản được giữ nguyên nhưng không
  tự gán cho người đang đăng nhập; tủ sách mới sẽ được lấy từ API.
- Đánh giá sao vẫn cần mạng. Settings đọc vẫn là thiết lập trên máy.
- Quy tắc conflict và endpoint xem [API contract](../reader-api/CONTRACT.md).
  Phải triển khai API mới trước app; với API cũ, outbox vẫn được giữ để thử lại.

Kiểm thử offline: `flutter test test/offline_sync_test.dart`.

### Mở truyện không chờ mạng

- Truyện đã tải: chi tiết, mục lục và nội dung chương đọc local trước,
  không gọi API truyện hay kiểm tra kết nối trên đường mở sách (kể cả mở bằng slug).
- Truyện chỉ có cache: chi tiết và mục lục hiển thị cache ngay, sau đó làm mới
  ở nền; API lỗi vẫn giữ dữ liệu đang hiển thị. Chương đã lưu được mở ngay và
  giữ ổn định trong phiên đọc; muốn thay nội dung bản tải dùng **Cập nhật**.
- Chương chưa lưu mới cần API. Đồng bộ tủ sách/tiến độ vẫn hoạt động độc lập,
  không phải điều kiện để mở sách; không lấy lại tủ sách mỗi lần vào chi tiết.
- Truy vấn mục lục/cờ tải chỉ lấy metadata và ID, không đọc toàn bộ văn bản
  của các chương. Điều này tránh tải cả truyện vào RAM chỉ để hiện mục lục.

### TTS trên Android

- Android chỉ dùng foreground service native để phát. Flutter gửi lệnh và phản
  ánh trạng thái; không khởi động thêm engine Flutter khi service gặp lỗi.
- Chuyển chương tự động đọc cùng SQLite local trước, kể cả khi màn hình đang ở
  nền. Chỉ chương chưa lưu mới gọi API, với timeout hữu hạn và không tự retry
  liên tục. Khi lỗi, giữ ý định sang chương và chờ nút tiếp tục để thử lại.
- Dừng, tạm dừng hoặc đổi chương hủy tác vụ tải đang chờ; phản hồi/callback cũ
  không được tự phát lại. Tiếp tục sau lỗi mạng thử chương còn thiếu, không đọc
  lại câu cuối chương cũ. Lỗi engine lặp lại sẽ tạm dừng thay vì bỏ qua văn bản.
- Ưu tiên giọng tiếng Việt không cần mạng. Giọng cần mạng do người dùng chọn
  vẫn phụ thuộc engine của thiết bị. Có thể bật hỗ trợ chạy nền/tối ưu pin trong
  cài đặt đọc; app không ép cấp quyền bằng hộp thoại lặp khi khởi động.

Kiểm thử thiết bị (cài song song `Reader TTS Test`, không thay bản Play Store):
```sh
python3 scripts/test_tts_device.py DEVICE_ID
```
Bản thử này không cấu hình Google Sign-In. Script tự đưa app ra nền và mở lại
để kiểm tra phát nền. Flutter tự gỡ package kiểm thử khi kết thúc; luôn chạy qua
script để dùng package test riêng và kiểm tra bản Play Store không bị thay đổi.
Suite tạo/xóa chương mẫu riêng,
không cần tắt Wi-Fi và không dùng tài khoản thật.
