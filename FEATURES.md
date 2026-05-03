# Features - Reader Android App

Trang thai tinh nang mobile `reader-app` theo parity voi web.

## Guest/User-facing

| Feature | Status | Notes |
|---|---|---|
| Google login | done | Qua `/api/auth/mobile-login` |
| Home/browse boards | done | `/api/novels/browse` |
| Genre list | done | `/api/genres` |
| Novel detail + chapter list | done | `/api/novels/{idOrSlug}`, `/api/truyen/{id}/chapters` |
| Reader chapter detail | done | `/api/chapters/{chapterId}` |
| Bookmark | done | `/api/user/bookmarks` |
| Reading progress sync | done | `/api/user/reading-progress` |
| Comments | done | `/api/truyen/{id}/comments` |

## Parity Gaps

| Feature | Status | Notes |
|---|---|---|
| User settings sync | planned | `/api/user/settings` |
| User recommendations | planned | `/api/user/recommendations` |
| Rating | planned | `/api/truyen/{id}/rate` |
| Search suggest | planned | `/api/truyen/suggest` |

## Dependencies

- Contract: `reader-app/CONTRACT.md`
- Mapping: `reader-app/CROSS_REPO_ENDPOINT_MATRIX.md`

## Note

- EPUB import flow is currently MOD-only on web (`reader /mod/import`), not in mobile scope.
