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

**Skill version: 1.0.0**

Upload any file and get a short-lived URL. No account required. Files expire after 24 hours.

To install or update: `npx skills add zoomie-sh/skill --skill zoomie -g`

## Requirements

- Required: `curl`
- Optional: `jq` (for structured output)

## Upload a file

```bash
./scripts/upload.sh /path/to/file.pdf
```

Outputs the live URL (e.g. `https://zoomie.sh/f/sunny-otter-ab12cd34`).

## Supported file types

| Category  | MIME types |
|-----------|------------|
| Images    | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml` |
| Documents | `application/pdf`, `text/plain`, `text/markdown` |
| Data/Code | `application/json`, `text/csv`, `text/xml`, `application/xml`, `text/html` |
| Archives  | `application/zip`, `application/gzip`, `application/x-tar` |

Max file size: **50 MB**. Rate limited to **20 uploads / minute**.

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
- Images and PDFs render inline in the browser. Append `?download=1` to force a file download.

## Errors

| Status | Cause |
|--------|-------|
| `422` | Missing file, unsupported type, or exceeds 50 MB |
| `429` | Rate limit exceeded |

## Full API reference

See [references/REFERENCE.md](references/REFERENCE.md) for the complete API reference.
