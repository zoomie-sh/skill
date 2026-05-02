#!/usr/bin/env bash
# Share markdown content via Zoomie and return a shareable URL.
#
# Usage:
#   ./scripts/share.sh "# My content"          — inline string
#   ./scripts/share.sh path/to/file.md          — read from file
#   echo "# content" | ./scripts/share.sh -    — read from stdin
#
# Optional flags:
#   --title "My title"      Set a title (max 100 chars)
#   --summary "..."         Set a summary (max 500 chars)
#
# Set $ZOOMIE_TOKEN for permanent (non-expiring) storage.

set -euo pipefail

API="https://zoomie.sh/api/v1"
STATE_FILE="$HOME/.zoomie/state.json"
TITLE=""
SUMMARY=""
CONTENT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)   TITLE="$2";   shift 2 ;;
    --summary) SUMMARY="$2"; shift 2 ;;
    *)
      if [[ -z "$CONTENT" ]]; then
        CONTENT="$1"
      fi
      shift
      ;;
  esac
done

# Read content from file or stdin
if [[ "$CONTENT" == "-" ]]; then
  CONTENT=$(cat)
elif [[ -f "$CONTENT" ]]; then
  CONTENT=$(cat "$CONTENT")
elif [[ -z "$CONTENT" ]]; then
  echo "Error: no content provided." >&2
  echo "Usage: ./scripts/share.sh \"# My content\" [--title \"...\"] [--summary \"...\"]" >&2
  exit 1
fi

# Build JSON payload
PAYLOAD=$(jq -n \
  --arg content "$CONTENT" \
  --arg title   "$TITLE" \
  --arg summary "$SUMMARY" \
  '{content: $content} +
   (if $title   != "" then {title:   $title}   else {} end) +
   (if $summary != "" then {summary: $summary} else {} end)')

# Build curl args
CURL_ARGS=(-s -X POST "$API/files" -H "Content-Type: application/json" -d "$PAYLOAD")

if [[ -n "${ZOOMIE_TOKEN:-}" ]]; then
  CURL_ARGS+=(-H "Authorization: Bearer $ZOOMIE_TOKEN")
fi

RESPONSE=$(curl "${CURL_ARGS[@]}")

# Check for API errors
if echo "$RESPONSE" | jq -e '.message' > /dev/null 2>&1 && ! echo "$RESPONSE" | jq -e '.html_url' > /dev/null 2>&1; then
  echo "Error: $(echo "$RESPONSE" | jq -r '.message')" >&2
  exit 1
fi

# Persist state for anonymous uploads (upload_token enables later update/delete)
UPLOAD_TOKEN=$(echo "$RESPONSE" | jq -r '.upload_token // empty')
if [[ -n "$UPLOAD_TOKEN" ]]; then
  mkdir -p "$(dirname "$STATE_FILE")"
  echo "$RESPONSE" | jq '{slug, html_url, markdown_url, upload_token, expires_at}' > "$STATE_FILE"
fi

# Output the shareable URL
echo "$RESPONSE" | jq -r '.html_url'
