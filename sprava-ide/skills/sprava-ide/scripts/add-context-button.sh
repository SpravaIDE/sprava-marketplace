#!/bin/bash
ID="$1"
LABEL="$2"
COMMAND="$3"
MODE="${4:-normal}"
COLOR="$5"
if [ -z "$ID" ] || [ -z "$LABEL" ] || [ -z "$COMMAND" ]; then
  echo "usage: add-context-button.sh <id> <label> <command> [mode] [color]" >&2
  exit 1
fi
ESC_ID=$(printf '%s' "$ID" | sed 's/\\/\\\\/g; s/"/\\"/g')
ESC_LABEL=$(printf '%s' "$LABEL" | sed 's/\\/\\\\/g; s/"/\\"/g')
ESC_COMMAND=$(printf '%s' "$COMMAND" | sed 's/\\/\\\\/g; s/"/\\"/g')
if [ -n "$COLOR" ]; then
  ESC_COLOR=$(printf '%s' "$COLOR" | sed 's/\\/\\\\/g; s/"/\\"/g')
  BODY="{\"id\": \"$ESC_ID\", \"label\": \"$ESC_LABEL\", \"command\": \"$ESC_COMMAND\", \"mode\": \"$MODE\", \"color\": \"$ESC_COLOR\"}"
else
  BODY="{\"id\": \"$ESC_ID\", \"label\": \"$ESC_LABEL\", \"command\": \"$ESC_COMMAND\", \"mode\": \"$MODE\"}"
fi
curl -s -X POST "http://localhost:$SPRAVA_PORT/api/terminals/$SPRAVA_TERMINAL_ID/contextbuttons" \
  -H "Content-Type: application/json" \
  -d "$BODY"
