# Zoomie API Reference

Base URL: `https://zoomie.sh/api/v0`

---

## Upload a File

**`POST /api/v0/upload`**

Stores a file and returns a temporary download URL. Rate limited to 20 requests per minute.

### Request

`multipart/form-data` with a single `file` field.

| Constraint | Value |
|---|---|
| Max size | 50 MB |
| Allowed types | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml`, `application/pdf`, `text/plain`, `text/markdown`, `application/json`, `text/csv`, `text/xml`, `application/xml`, `text/html`, `application/zip`, `application/gzip`, `application/x-tar` |

### Response `201`

```json
{
  "url": "https://zoomie.sh/f/sunny-otter-ab12cd34",
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

Records a plain-text feedback message. Intended for AI agents. Rate limited to 10 requests per minute.

### Request

`application/json` with a single `message` field.

| Constraint | Value |
|---|---|
| Max length | 2000 chars |

### Response `201`

```json
{
  "id": 1,
  "created_at": "2026-04-14T21:55:29+00:00"
}
```

| Field | Description |
|---|---|
| `id` | ID of the created feedback record |
| `created_at` | ISO 8601 timestamp |

### Error responses

| Status | Cause |
|---|---|
| `422` | Missing or oversized message (> 2000 chars) |
| `429` | Rate limit exceeded |

---

## Retrieve a File

**`GET /f/{slug}`**

Serves the file inline (e.g. renders an image or PDF in the browser). Returns `404` if the slug is unknown or the file has expired.

### Query parameters

| Param | Value | Effect |
|---|---|---|
| `download` | `1` or `true` | Forces a file download instead of inline rendering |

### Examples

```
GET /f/sunny-otter-ab12cd34           → inline (Content-Disposition: inline)
GET /f/sunny-otter-ab12cd34?download=1 → download (Content-Disposition: attachment)
```

### Error responses

| Status | Cause |
|---|---|
| `404` | Slug not found or file expired |

---

## Notes

- Files expire **24 hours** after upload.
- Slugs are unique and take the form `adjective-animal-random8` (e.g. `misty-capybara-kx9fqrzt`).
- No authentication required for any endpoint.
