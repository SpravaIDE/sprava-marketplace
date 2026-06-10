#!/bin/bash
STATUS="$1"
if [ -z "$STATUS" ]; then
  echo "usage: set-task-status.sh <status>" >&2
  exit 1
fi
TASK_ID="${SPRAVA_TASK_ID%%:*}"
if [ -z "$TASK_ID" ]; then
  echo "set-task-status.sh: no task in context (SPRAVA_TASK_ID unset)" >&2
  exit 1
fi
ESC_STATUS=$(printf '%s' "$STATUS" | sed 's/\\/\\\\/g; s/"/\\"/g')
curl -s -X PATCH "http://localhost:$SPRAVA_PORT/api/projects/$SPRAVA_PROJECT_ID/tasks/$TASK_ID/status" \
  -H "Content-Type: application/json" \
  -d "{\"status\": \"$ESC_STATUS\"}"
