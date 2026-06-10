#!/bin/bash
MESSAGE="$1"
LEVEL="${2:-info}"
if [ -z "$MESSAGE" ]; then
  echo "usage: notify.sh <message> [level]" >&2
  exit 1
fi
ESC_MESSAGE=$(printf '%s' "$MESSAGE" | sed 's/\\/\\\\/g; s/"/\\"/g')
curl -s -X POST "http://localhost:$SPRAVA_PORT/api/terminals/$SPRAVA_TERMINAL_ID/notify" \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"$ESC_MESSAGE\", \"level\": \"$LEVEL\"}"
