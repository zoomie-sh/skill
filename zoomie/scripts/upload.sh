#!/usr/bin/env bash
set -euo pipefail

# Upload a file to Zoomie and print the shareable URL.
#
# Usage: ./upload.sh <file-path>
#
# Environment variables:
#   ZOOMIE_BASE_URL  Override the API base URL (default: https://zoomie.sh)

BASE_URL="${ZOOMIE_BASE_URL:-https://zoomie.sh}"

if [[ $# -eq 0 ]]; then
    echo "Usage: $(basename "$0") <file-path>" >&2
    exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "Error: file not found: $FILE" >&2
    exit 1
fi

RESPONSE=$(curl -sS -w "\n%{http_code}" \
    -X POST "$BASE_URL/api/v0/files" \
    -F "file=@$FILE")

HTTP_CODE=$(printf '%s' "$RESPONSE" | tail -n1)
BODY=$(printf '%s' "$RESPONSE" | head -n-1)

if [[ "$HTTP_CODE" == "201" ]]; then
    if command -v jq &>/dev/null; then
        printf '%s' "$BODY" | jq -r '.url'
    else
        printf '%s' "$BODY" | grep -o '"url":"[^"]*"' | cut -d'"' -f4
    fi
else
    echo "Error $HTTP_CODE: $BODY" >&2
    exit 1
fi
