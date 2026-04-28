---
name: zoomie
description: >
  Upload files and get a temporary shareable URL. No account or API key required.
  Use when asked to "share this file", "upload this", "get a link for this file",
  "host this file temporarily", "send this file", "make this downloadable",
  "generate a download link", or "upload to zoomie".
  Returns a live URL that expires in 24 hours.
---

# Zoomie

**Skill version: 2.0.0**

Upload any file and get a short-lived URL. No account required. Files expire after 24 hours.

To install or update: `npx skills add zoomie-sh/skill --skill zoomie -g`

## Requirements

- Required: `curl`
- Optional: `jq` (for structured output)

## Upload a file

Anonymous (no account needed):

```bash
./scripts/upload.sh /path/to/file.pdf
```

Authenticated:

```bash
curl -s -X POST https://zoomie.sh/api/v0/files \
  -H "Authorization: Bearer $ZOOMIE_TOKEN" \
  -F "file=@/path/to/file.pdf"
```

Outputs the live URL (e.g. `https://zoomie.sh/api/v0/files/sunny-otter-ab12cd34`).

## Supported file types

| Category  | MIME types |
|-----------|------------|
| Images    | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml` |
| Documents | `application/pdf`, `text/plain`, `text/markdown` |
| Data/Code | `application/json`, `text/csv`, `text/xml`, `application/xml`, `text/html` |
| Archives  | `application/zip`, `application/gzip`, `application/x-tar` |

Max file size: **50 MB**.

## Authentication (optional)

Get a token via two API calls — no browser needed.

**Step 1 — Request a code:**

```bash
curl -s -X POST https://zoomie.sh/api/v0/auth/request-code \
  -H "Content-Type: application/json" \
  -d '{"email": "you@example.com"}'
```

**Step 2 — Verify and get token:**

```bash
curl -s -X POST https://zoomie.sh/api/v0/auth/verify-code \
  -H "Content-Type: application/json" \
  -d '{"email": "you@example.com", "code": "ABCD-1234"}'
```

Returns `{ "token": "1|abc123...", "token_type": "Bearer" }`. Store and reuse the token.

Agents with their own inboxes (e.g. AgentMail) can fully automate this flow.

## Response fields

| Field | Description |
|-------|-------------|
| `url` | Direct link to the uploaded file |
| `slug` | Unique identifier in `adjective-animal-random8` format |
| `expires_at` | ISO 8601 expiry timestamp — file is deleted after this |
| `size` | File size in bytes |
| `original_name` | Original filename as uploaded |

## What to tell the user

- Always share the `url` from the response.
- Remind the user the link **expires in 24 hours**.
- All files are served as downloads (attachment).

## Errors

| Status | Cause |
|--------|-------|
| `422` | Missing file, unsupported type, or exceeds 50 MB |

## Manage files (authenticated only)

**List uploads:**

```bash
curl -s https://zoomie.sh/api/v0/files \
  -H "Authorization: Bearer $ZOOMIE_TOKEN"
```

**Rename an upload:**

```bash
curl -s -X PUT https://zoomie.sh/api/v0/files/{slug} \
  -H "Authorization: Bearer $ZOOMIE_TOKEN" \
  -H "Content-Type: application/json" \
  -F "file=@/path/to/new-file.pdf"
```

**Delete an upload:**

```bash
curl -s -X DELETE https://zoomie.sh/api/v0/files/{slug} \
  -H "Authorization: Bearer $ZOOMIE_TOKEN"
```

## Submit feedback

```bash
curl -s -X POST https://zoomie.sh/api/v0/feedback \
  -H "Content-Type: application/json" \
  -d '{"message": "Your feedback here."}'
```

Returns `201` with `{"status": "ok"}`. Max 2000 characters. Optional auth: include Bearer token to associate feedback with a user.

## Full API reference

See [references/REFERENCE.md](references/REFERENCE.md) for the complete API reference.
