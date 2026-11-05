#!/bin/bash
# POST a file to the current session's file list in the Sprava IDE (sessions without a task).
# env: $SPRAVA_PORT, $SPRAVA_TERMINAL_ID (present in Sprava IDE terminals)
set -euo pipefail

FILE_PATH="${1:-}"
if [ -z "$FILE_PATH" ]; then
  echo "usage: add-session-file.sh <absolute-path>" >&2
  exit 1
fi

if [ -z "${SPRAVA_PORT:-}" ] || [ -z "${SPRAVA_TERMINAL_ID:-}" ]; then
  echo "add-session-file.sh: \$SPRAVA_PORT and \$SPRAVA_TERMINAL_ID must be set (run inside a Sprava IDE terminal)" >&2
  exit 1
fi

ESC_PATH=$(printf '%s' "$FILE_PATH" | sed 's/\\/\\\\/g; s/"/\\"/g')

BODY_OUT=$(mktemp)
trap 'rm -f "$BODY_OUT"' EXIT

HTTP_CODE=$(curl -sS -o "$BODY_OUT" -w '%{http_code}' -X POST \
  "http://localhost:$SPRAVA_PORT/api/terminals/$SPRAVA_TERMINAL_ID/sessionfiles" \
  -H "Content-Type: application/json" \
  -d "{\"filePath\": \"$ESC_PATH\"}")

cat "$BODY_OUT"

if [ "$HTTP_CODE" -ge 400 ]; then
  echo >&2
  echo "add-session-file.sh: IDE returned HTTP $HTTP_CODE" >&2
  exit 1
fi
