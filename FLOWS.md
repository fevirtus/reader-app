# Flows - Reader Android App

Muc tieu: mobile follow cung business behavior voi web.

## Flow 1: Mobile Login and Token

- Trigger: user dang nhap Google tren app.
- Steps:
  1. Lay Google token.
  2. Goi `/api/auth/mobile-login` doi lay app JWT.
  3. Luu JWT, goi `/api/user/profile` hydrate session.
- Failure:
  - token invalid -> `401`
  - profile unavailable -> retry + user notice

## Flow 2: Discover and Read

- Discover:
  - `/api/genres`
  - `/api/novels/browse`
  - `/api/novels/{idOrSlug}`
- Read:
  - `/api/truyen/{id}/chapters`
  - `/api/chapters/{chapterId}`
- Expected: state chapter/current progress dong bo server.

## Flow 3: Bookmark and Progress

- Bookmark add/remove/sync:
  - `GET/POST/DELETE /api/user/bookmarks`
- Progress sync:
  - `POST /api/user/reading-progress`
- Rule: optimistic UI + rollback neu API fail.

## Flow 4: Comment Interaction

- Load comments:
  - `GET /api/truyen/{id}/comments`
- Post comment:
  - `POST /api/truyen/{id}/comments`
- Rule: require login, follow error contract chung.

## Planned Flows (Parity)

- Settings sync flow (`/api/user/settings`)
- Recommendation flow (`/api/user/recommendations`)
- Rating flow (`/api/truyen/{id}/rate`)
- Search suggest flow (`/api/truyen/suggest`)

## Out of Scope (Current)

- MOD EPUB import chi tren web (`/mod/import`: `/api/mod/epub`, `POST /api/import/uploads/preview`, …). Mobile khong co wizard import.
