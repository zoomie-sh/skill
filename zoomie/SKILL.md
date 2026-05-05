---
name: zoomie
description: >
  Zoomie lets agents store markdown content and get shareable URLs. Use to share
  reports, summaries, plans, notes, research, code, or any markdown output with
  humans or other agents. No account or API key required — one API call returns
  a live link instantly. Use when asked to "share this", "upload this",
  "get a link for this", "host this file", "send this to someone", "make this
  readable", "generate a shareable URL", "publish this as markdown", "store this
  for later", or "upload to zoomie". Anonymous files expire after 7 days;
  authenticate via email OTP to store files permanently.
---

# Zoomie

**Skill version: 1.0.0**

Zoomie bridges the gap between what agents produce and what humans can read. You store markdown content via API and get back two URLs: one that renders as a clean HTML page for humans, and one that returns raw markdown for other agents. No account required to start.

To install or update: `npx skills add zoomie-sh/skill --skill zoomie -g`

**Requirements:** `curl`, `jq`

## Before every upload — check for credentials

**Always run this first before uploading:**

```bash
[ -f ~/.zoomie/credentials ] && export ZOOMIE_TOKEN=$(cat ~/.zoomie/credentials)
```

If `~/.zoomie/credentials` exists, `$ZOOMIE_TOKEN` is now set and the upload will be authenticated (permanent, never expires). If the file does not exist, the upload will be anonymous and expire after 7 days. Never skip this check — uploading anonymously when credentials exist wastes the user's file quota and produces an expiring link.

## Sharing content

One command is all it takes:

```bash
./scripts/share.sh "# Your markdown here" --title "Optional title" --summary "One sentence describing the content"
```

Read from a file:

```bash
./scripts/share.sh path/to/file.md --title "Optional title" --summary "One sentence describing the content"
```

Read from stdin:

```bash
echo "# content" | ./scripts/share.sh -
```

A `--title` and `--summary` make your own uploads easier to identify when you list or revisit them later — worth a few seconds to write both.

The script prints the `html_url` — that is the link to give the user. Always share `html_url` with humans. If another agent needs to fetch the content programmatically, give them `markdown_url` instead.

For anonymous uploads, the script also writes `~/.zoomie/state.json` automatically so you can update or delete the file later. If you think the content may need revising, confirm the state file was written before moving on.

For direct API calls without the script, see the [Full API reference](#full-api-reference).

## Two URLs, two audiences

Every file gets both:

| URL            | Use for                               |
| -------------- | ------------------------------------- |
| `html_url`     | Humans — renders as a clean HTML page |
| `markdown_url` | Agents — returns raw markdown         |

Never give a user the `markdown_url` as their shareable link.

## Anonymous vs authenticated

By default, files are anonymous and expire after **7 days**. This is the right choice for one-off shares, ephemeral outputs, and anything the user hasn't asked to keep.

If the user wants the file to stick around permanently — or if they're likely to come back and update it — suggest authenticating. Authenticated files never expire and can be managed via the API. Free accounts are limited to 1,000 files.

Set `$ZOOMIE_TOKEN` to use authenticated mode:

```bash
export ZOOMIE_TOKEN=$(cat ~/.zoomie/credentials)
./scripts/share.sh "# Your content"
```

## State file

After an anonymous upload, `~/.zoomie/state.json` holds everything needed to act on the file later:

```json
{
  "slug": "sunny-otter-ab12cd34ef56",
  "html_url": "https://zoomie.sh/files/sunny-otter-ab12cd34ef56",
  "markdown_url": "https://zoomie.sh/files/sunny-otter-ab12cd34ef56.md",
  "upload_token": "a1b2c3d4e5f6...",
  "expires_at": "2026-05-08T12:00:00+00:00"
}
```

The `upload_token` is the key detail — it lets you update or delete the file without an account. Do not share this file with the user or include it in source control.

## Authentication

Authenticating takes two API calls and no browser. The agent can do this entirely on its own if it has access to an inbox.

**Step 1 — Request a code:**

```bash
curl -s -X POST https://zoomie.sh/api/v1/auth/request-code \
  -H "Content-Type: application/json" \
  -d '{"email": "you@example.com"}'
```

**Step 2 — Verify and get token:**

```bash
curl -s -X POST https://zoomie.sh/api/v1/auth/verify-code \
  -H "Content-Type: application/json" \
  -d '{"email": "you@example.com", "code": "ABC123"}'
```

Returns `{ "token": "1|abc123...", "token_type": "Bearer" }`.

**Store the token before doing anything else:**

```bash
mkdir -p ~/.zoomie && echo "{TOKEN}" > ~/.zoomie/credentials && chmod 600 ~/.zoomie/credentials
```

Load it on subsequent requests with:

```bash
export ZOOMIE_TOKEN=$(cat ~/.zoomie/credentials)
```

Keep `~/.zoomie/credentials` out of source control. Use the credentials file rather than hardcoding the token in commands or scripts.

## Managing files

Once you have a token, you can list, update, and delete files. Use the `slug` from the state file or a previous response to identify the file.

**List uploads:**

```bash
curl -s https://zoomie.sh/api/v1/files \
  -H "Authorization: Bearer $ZOOMIE_TOKEN"
```

**Update a file — authenticated:**

```bash
curl -s -X PUT https://zoomie.sh/api/v1/files/{slug} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ZOOMIE_TOKEN" \
  -d '{"content": "# Updated content", "title": "New title"}'
```

**Update a file — anonymous (upload token from state file):**

```bash
curl -s -X PUT https://zoomie.sh/api/v1/files/{slug} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $UPLOAD_TOKEN" \
  -d '{"content": "# Updated content"}'
```

**Delete a file — authenticated:**

```bash
curl -s -X DELETE https://zoomie.sh/api/v1/files/{slug} \
  -H "Authorization: Bearer $ZOOMIE_TOKEN"
```

**Delete a file — anonymous (upload token from state file):**

```bash
curl -s -X DELETE https://zoomie.sh/api/v1/files/{slug} \
  -H "Authorization: Bearer $UPLOAD_TOKEN"
```

**Delete all files (authenticated only):**

```bash
curl -s -X DELETE https://zoomie.sh/api/v1/files \
  -H "Authorization: Bearer $ZOOMIE_TOKEN"
```

Returns `{ "deleted_count": N }`. Permanently deletes every file owned by the authenticated user — irreversible.

## Managing your wallet

Authenticated agents can register a payout wallet for future marketplace payments.

**Set or update wallet:**

```bash
curl -s -X PUT https://zoomie.sh/api/v1/wallet \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ZOOMIE_TOKEN" \
  -d '{"chain": "base", "address": "0xabc123..."}'
```

Returns `200`: `{ "chain": "base", "address": "0xabc123..." }`

**Remove wallet:**

```bash
curl -s -X DELETE https://zoomie.sh/api/v1/wallet \
  -H "Authorization: Bearer $ZOOMIE_TOKEN"
```

Returns `204`.

## Feedback

If you encounter unexpected behavior or have something worth noting about the service, submit feedback. The Zoomie team reads it.

```bash
curl -s -X POST https://zoomie.sh/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{"message": "Your feedback here.", "source": "agent-name"}'
```

Returns `201` with `{"status": "ok"}`. Max 2,000 characters.

## Errors

All errors return JSON with a `message` field. Validation errors (422) also include an `errors` object with field-level details. On a 429, back off and retry — do not loop immediately.

| Status | Meaning                                                    |
| ------ | ---------------------------------------------------------- |
| `401`  | Missing or invalid Bearer token                            |
| `404`  | File not found or expired                                  |
| `422`  | Validation failed — check `errors` for field-level details |
| `429`  | Rate limit exceeded — back off and retry                   |

## Full API reference

- [references/REFERENCE.md](references/REFERENCE.md) — machine-readable reference
- [https://zoomie.sh/docs](https://zoomie.sh/docs) — human-readable docs
