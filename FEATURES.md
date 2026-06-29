# Features - Reader Android App

Trang thai tinh nang mobile `reader-app` theo parity voi web.

## Guest/User-facing

| Feature | Status | Notes |
|---|---|---|
| Google login | done | Qua `/api/auth/mobile-login` |
| Home/browse boards | done | Hot, xep hang danh gia/luot doc, truyen moi |
| Genre list | done | `/api/genres` |
| Novel detail + chapter list | done | `/api/novels/{idOrSlug}`, `/api/truyen/{id}/chapters` |
| Reader chapter detail | done | `/api/chapters/{chapterId}` |
| Bookshelf (dang doc / da doc) | done | 2 tab, khong con kệ danh dau |
| Mark as read | done | `POST /api/user/bookmarks` action `markAsRead` |
| Reading progress sync | done | `/api/user/reading-progress` |
| Rating | done | `/api/truyen/{id}/rate` thang 1-10 |

## Parity Gaps

| Feature | Status | Notes |
|---|---|---|
| User settings sync | planned | `/api/user/settings` |
| Search suggest | planned | `/api/truyen/suggest` |

## Dependencies

- Contract: `reader-app/CONTRACT.md`
- Mapping: `reader-app/CROSS_REPO_ENDPOINT_MATRIX.md`

## Note

- EPUB import flow is currently MOD-only on web (`reader /mod/import`), not in mobile scope.
