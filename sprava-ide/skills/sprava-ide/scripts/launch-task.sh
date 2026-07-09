#!/bin/bash
# POST a task launch to the Sprava IDE — opens a terminal for <taskId> (optionally <subtaskId>).
# Runs the project's default run configuration for that scope; pass <input> to run a free-form
# command/prompt instead. Reuses the calling terminal's pane when it is completed/idle (via
# $SPRAVA_TERMINAL_ID), otherwise opens a new tab.
# env: $SPRAVA_PORT, $SPRAVA_PROJECT_ID (and $SPRAVA_TERMINAL_ID in Sprava IDE claude terminals)
set -euo pipefail

if [ -z "${SPRAVA_PORT:-}" ] || [ -z "${SPRAVA_PROJECT_ID:-}" ]; then
  echo "launch-task.sh: \$SPRAVA_PORT and \$SPRAVA_PROJECT_ID must be set (run inside a Sprava IDE terminal)" >&2
  exit 1
fi

TASK_ID="${1:-}"
SUBTASK_ID="${2:-}"
INPUT="${3:-}"
if [ -z "$TASK_ID" ]; then
  echo "usage: launch-task.sh <taskId> [subtaskId] [input]" >&2
  exit 1
fi

json_str() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

BODY="{"
SEP=""
if [ -n "$SUBTASK_ID" ]; then
  BODY="$BODY$SEP\"subtaskId\": \"$(json_str "$SUBTASK_ID")\""
  SEP=", "
fi
if [ -n "$INPUT" ]; then
  BODY="$BODY$SEP\"input\": \"$(json_str "$INPUT")\""
  SEP=", "
fi
if [ -n "${SPRAVA_TERMINAL_ID:-}" ]; then
  BODY="$BODY$SEP\"originTerminalId\": \"$(json_str "$SPRAVA_TERMINAL_ID")\""
  SEP=", "
fi
BODY="$BODY}"

BODY_OUT=$(mktemp)
trap 'rm -f "$BODY_OUT"' EXIT

HTTP_CODE=$(curl -sS -o "$BODY_OUT" -w '%{http_code}' -X POST \
  -H "Content-Type: application/json" \
  -d "$BODY" \
  "http://localhost:$SPRAVA_PORT/api/projects/$SPRAVA_PROJECT_ID/tasks/$TASK_ID/launch")

cat "$BODY_OUT"

if [ "$HTTP_CODE" -ge 400 ]; then
  echo >&2
  echo "launch-task.sh: IDE returned HTTP $HTTP_CODE" >&2
  exit 1
fi
