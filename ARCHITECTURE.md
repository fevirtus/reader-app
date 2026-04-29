# Reader Suite Architecture (Android/Flutter)

Tai lieu nay mo ta vai tro `reader-app` trong he sinh thai doc truyen gom web + mobile + backend.

## Vai tro trong he thong

- `reader-app` la mobile client cho end-user feature.
- KHONG chua logic nghiep vu canonic; backend (`reader-api`) la noi quyet dinh rule.
- Muc tieu: feature parity voi web user-facing, tru workflow MOD/ADMIN.

## Kien truc app

- `lib/core`: config, networking, storage, app-level services.
- `lib/features`: module theo domain (auth, browse, novel-detail, reader, bookshelf...).
- `lib/shared`: widget dung chung.

## Nguyen tac dong bo voi web + backend

- Dung chung endpoint contract voi web, khong tao API rieng cho mobile neu khong can thiet.
- Dung chung semantic cho state:
  - bookmark
  - reading-progress
  - recommendation
  - user-settings
- Auth mobile qua JWT; backend phai map cung identity voi web.

## Environment va ket noi

- Local API mac dinh: `http://10.0.2.2:8000` (Android emulator).
- Script `scripts/flutter_run_with_env.sh` la cach chuan de chay local.
- `BASE_URL`, `GOOGLE_SERVER_CLIENT_ID`, `GOOGLE_CLIENT_ID` duoc truyen qua `--dart-define`.

## Definition of Done (Mobile)

- API calls tuan thu contract `reader-api` (status code + error format).
- UX/state nhat quan voi web cho luong user-facing.
- Da test tren it nhat Android emulator + 1 moi truong khac (iOS simulator hoac device).
- Cac huong dan env/auth trong README van dung sau thay doi.
