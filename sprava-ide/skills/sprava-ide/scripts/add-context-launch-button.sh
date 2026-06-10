#!/bin/bash
ID="$1"
LABEL="$2"
TASK_ID="$3"
SUBTASK_ID="$4"
MODE="${5:-normal}"
COLOR="$6"
if [ -z "$ID" ] || [ -z "$LABEL" ] || [ -z "$TASK_ID" ]; then
  echo "usage: add-context-launch-button.sh <id> <label> <taskId> [subtaskId] [mode] [color]" >&2
  exit 1
fi
ESC_ID=$(printf '%s' "$ID" | sed 's/\\/\\\\/g; s/"/\\"/g')
ESC_LABEL=$(printf '%s' "$LABEL" | sed 's/\\/\\\\/g; s/"/\\"/g')
ESC_TASK_ID=$(printf '%s' "$TASK_ID" | sed 's/\\/\\\\/g; s/"/\\"/g')
LAUNCH="{\"taskId\": \"$ESC_TASK_ID\""
if [ -n "$SUBTASK_ID" ]; then
  ESC_SUBTASK_ID=$(printf '%s' "$SUBTASK_ID" | sed 's/\\/\\\\/g; s/"/\\"/g')
  LAUNCH="$LAUNCH, \"subtaskId\": \"$ESC_SUBTASK_ID\""
fi
LAUNCH="$LAUNCH}"
BODY_HEAD="{\"id\": \"$ESC_ID\", \"label\": \"$ESC_LABEL\", \"mode\": \"$MODE\""
if [ -n "$COLOR" ]; then
  ESC_COLOR=$(printf '%s' "$COLOR" | sed 's/\\/\\\\/g; s/"/\\"/g')
  BODY_HEAD="$BODY_HEAD, \"color\": \"$ESC_COLOR\""
fi
BODY="$BODY_HEAD, \"launch\": $LAUNCH}"
curl -s -X POST "http://localhost:$SPRAVA_PORT/api/terminals/$SPRAVA_TERMINAL_ID/contextbuttons" \
  -H "Content-Type: application/json" \
  -d "$BODY"
