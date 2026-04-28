# Zoomie API Reference

Base URL: `https://zoomie.sh/api/v0`

---

## Authentication

Authentication is optional. All endpoints work anonymously. Authenticated users get a higher upload rate limit (60/min vs 20/min).

### Request a login code

**`POST /api/v0/auth/request-code`**

```bash
curl -s -X POST https://zoomie.sh/api/v0/auth/request-code \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'
```

Returns `200`: `{ "message": "Code sent to user@example.com" }`

Rate limit: 5 requests per hour per IP. Code expires in 10 minutes.

---

### Verify code and get token

**`POST /api/v0/auth/verify-code`**

```bash
curl -s -X POST https://zoomie.sh/api/v0/auth/verify-code \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "code": "ABCD-1234"}'
```

Dashes in the code are optional (`ABCD1234` also works).

Returns `200`:

```json
{
  "token": "1|abc123...",
  "token_type": "Bearer"
}
```

Rate limit: 10 requests per hour per IP.

---

## Health Check

**`GET /api/v0/health`**

Returns the service status. No authentication or rate limit.

### Response `200`

```json
{ "status": "ok" }
```

---

## Upload a File

**`POST /api/v0/files`**

Stores a file and returns a temporary download URL. Rate limited to 20 requests per minute (anonymous) or 60 requests per minute (authenticated).

Optionally include `Authorization: Bearer {token}` for the higher rate limit.

### Request

`multipart/form-data` with a single `file` field.

| Constraint | Value |
|---|---|
| Max size | 50 MB |
| Allowed types | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml`, `application/pdf`, `text/plain`, `text/markdown`, `application/json`, `text/csv`, `text/xml`, `application/xml`, `text/html`, `application/zip`, `application/gzip`, `application/x-tar` |

### Examples

Anonymous:

```bash
curl -s -X POST https://zoomie.sh/api/v0/files \
  -F "file=@/path/to/file.pdf"
```

Authenticated (higher rate limit):

```bash
curl -s -X POST https://zoomie.sh/api/v0/files \
  -H "Authorization: Bearer 1|abc123..." \
  -F "file=@/path/to/file.pdf"
```

### Response `201`

```json
{
  "url": "https://zoomie.sh/api/v0/files/sunny-otter-ab12cd34",
  "slug": "sunny-otter-ab12cd34",
  "expires_at": "2026-04-05T12:00:00+00:00",
  "size": 204800,
  "original_name": "report.pdf"
}
```

| Field | Description |
|---|---|
| `url` | Direct link to retrieve the file |
| `slug` | Unique identifier (`adjective-animal-random8`) |
| `expires_at` | ISO 8601 timestamp — file is deleted after this |
| `size` | File size in bytes |
| `original_name` | Original filename as uploaded |

### Error responses

| Status | Cause |
|---|---|
| `422` | Validation failed (missing file, wrong type, too large) |
| `429` | Rate limit exceeded |

---

## Submit Feedback

**`POST /api/v0/feedback`**

Records a plain-text feedback message. Intended for AI agents. Rate limited to 10 requests per minute. Optional auth: include Bearer token to associate feedback with a user.

### Request

`application/json` with a single `message` field.

| Constraint | Value |
|---|---|
| Max length | 2000 chars |

### Response `201`

```json
{ "status": "ok" }
```

| Field | Description |
|---|---|
| `status` | Always `"ok"` when feedback recorded |

### Error responses

| Status | Cause |
|---|---|
| `422` | Missing or oversized message (> 2000 chars) |
| `429` | Rate limit exceeded |

---

## Retrieve a File

**`GET /api/v0/files/{slug}`**

Downloads the file as an attachment (`Content-Disposition: attachment`). No authentication required. Returns `404` if the slug is unknown or the file has expired.

### Error responses

| Status | Cause |
|---|---|
| `404` | Slug not found or file expired |

---

## List Files

**`GET /api/v0/files`**

Returns a paginated list of the authenticated user's uploads, ordered newest first. Requires authentication.

```bash
curl -s https://zoomie.sh/api/v0/files \
  -H "Authorization: Bearer 1|abc123..."
```

Returns `200` with pagination envelope (`data`, `current_page`, `last_page`, `per_page`, `total`).

### Error responses

| Status | Cause |
|---|---|
| `401` | Unauthenticated |

---

## Update a File

**`PUT /api/v0/files/{slug}`**

Replaces the stored file. Metadata (name, MIME type, size) is derived from the new file. Expiry resets to 24 hours. Only the owner may update. Requires authentication.

```bash
curl -s -X PUT https://zoomie.sh/api/v0/files/sunny-otter-ab12cd34 \
  -H "Authorization: Bearer 1|abc123..." \
  -F "file=@/path/to/new-file.pdf"
```

Returns `200` with the updated upload object.

### Error responses

| Status | Cause |
|---|---|
| `401` | Unauthenticated |
| `403` | Upload does not belong to the authenticated user |
| `404` | Slug not found |
| `422` | Validation failed |

---

## Delete a File

**`DELETE /api/v0/files/{slug}`**

Permanently deletes the upload record and file from disk. Only the owner may delete. Requires authentication.

```bash
curl -s -X DELETE https://zoomie.sh/api/v0/files/sunny-otter-ab12cd34 \
  -H "Authorization: Bearer 1|abc123..."
```

Returns `204` no content.

### Error responses

| Status | Cause |
|---|---|
| `401` | Unauthenticated |
| `403` | Upload does not belong to the authenticated user |
| `404` | Slug not found |

---

## Notes

- Files expire **24 hours** after upload.
- Slugs are unique and take the form `adjective-animal-random8` (e.g. `misty-capybara-kx9fqrzt`).
- `store` and `show` are public — no auth needed. `index`, `update`, and `destroy` require a Bearer token.
