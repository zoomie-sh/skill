# Zoomie

> Zoomie is a markdown file hosting service. Store markdown content and get shareable HTML and raw markdown URLs. Anonymous files expire after 7 days. Authenticate via email OTP to store files permanently.

## API

Base URL: `https://zoomie.sh/api/v1`

All requests and responses use `application/json`.

### Authentication (optional)

Two-step email OTP. Authentication is optional — all endpoints work anonymously. Authenticated files never expire; anonymous files expire after 7 days.

**Step 1 — Request code**

`POST /api/v1/auth/request-code`

Body: `{ "email": "user@example.com" }`

Returns `200`: `{ "message": "Code sent to user@example.com" }`

Creates a user account if the email is new. Requesting a new code invalidates the previous active code.

Rate limit: 5 per 60 min per IP. Code expires in 10 minutes.

**Step 2 — Verify code**

`POST /api/v1/auth/verify-code`

Body: `{ "email": "user@example.com", "code": "ABC123" }`

Returns `200`: `{ "token": "1|abc123...", "token_type": "Bearer" }`

Codes are single-use and must match the email used for `request-code`.

Rate limit: 10 per 60 min per IP.

Use as `Authorization: Bearer {token}` on subsequent requests.

### Store a File

`POST /api/v1/files`

Body: `{ "content": "# markdown here", "title": "optional", "summary": "optional" }`

- `content` required, max 1,048,576 bytes (1 MB). `size` in the response reflects byte length.
- `title` optional, max 100 chars
- `summary` optional, max 500 chars

Rate limit: 20/min anonymous, 60/min authenticated.

Returns `201`:

```json
{
  "id": "...",
  "slug": "sunny-otter-ab12cd34ef56",
  "html_url": "https://zoomie.sh/files/sunny-otter-ab12cd34ef56",
  "markdown_url": "https://zoomie.sh/files/sunny-otter-ab12cd34ef56.md",
  "title": null,
  "summary": null,
  "size": 42,
  "expires_at": "2026-05-08T00:00:00+00:00",
  "created_at": "...",
  "updated_at": "...",
  "upload_token": "abc123..."
}
```

`upload_token` is only present for anonymous uploads. Use it as `Authorization: Bearer {upload_token}` to update or delete the file later. `expires_at` is omitted for authenticated files.

Free accounts limited to 1,000 files (`422` when reached).

Slugs use `adjective-animal-random12`, e.g. `sunny-otter-ab12cd34ef56`.

### Get a File

`GET /api/v1/files/{slug}`

Returns `200` with file resource (same shape as above, without `upload_token`). Returns `404` if expired or not found. No authentication required.

### List Files (authenticated)

`GET /api/v1/files` — requires `Authorization: Bearer {token}`

Returns paginated files, newest first, 20 per page.

Response: `{ "data": [...files], "links": {...}, "meta": { "current_page": 1, "last_page": N, "per_page": 20, "total": N } }`

### Update a File

`PUT /api/v1/files/{slug}` or `PATCH /api/v1/files/{slug}`

All fields optional — only include what you want to change.

Body: `{ "content": "...", "title": "...", "summary": "..." }`

Authenticated users: `Authorization: Bearer {token}`. Anonymous users: `Authorization: Bearer {upload_token}`.

Returns `200` with updated file resource. Returns `401` if no token or anonymous upload token is invalid, `404` if not found or not owned, `422` on validation errors.

### Delete a File

`DELETE /api/v1/files/{slug}`

Authenticated users: `Authorization: Bearer {token}`. Anonymous users: `Authorization: Bearer {upload_token}`.

Returns `204`. Returns `401` if no token or anonymous upload token is invalid, `404` if not found or not owned.

### Delete All Files (authenticated)

`DELETE /api/v1/files` — requires `Authorization: Bearer {token}`

Permanently deletes all files owned by the authenticated user. Irreversible.

Returns `200`: `{ "deleted_count": N }`

### Get Wallet (authenticated)

`GET /api/v1/wallet` — requires `Authorization: Bearer {token}`

Returns `200`: `{ "chain": "base"|null, "address": "0xabc123..."|null }`

### Set Wallet (authenticated)

`PUT /api/v1/wallet` — requires `Authorization: Bearer {token}`

Body: `{ "chain": "base", "address": "0xabc123..." }`

- `chain` required, must be one of: `base`
- `address` required, max 200 chars

Saves a payout wallet for marketplace payments. Replaces any previously saved wallet.

Returns `200`: `{ "chain": "base", "address": "0xabc123..." }`

### Remove Wallet (authenticated)

`DELETE /api/v1/wallet` — requires `Authorization: Bearer {token}`

Returns `204`.

### Submit Feedback

`POST /api/v1/feedback`

Body: `{ "message": "...", "source": "claude-sonnet-4-6" }` (`message` required, max 2000 chars; `source` optional)

Rate limit: 10 per 10 min per IP. IP recorded server-side. Optional auth associates feedback with user.

Returns `201`: `{ "status": "ok" }`

## Full API Reference

- [OpenAPI schema](/openapi.json)
