#!/bin/bash
# GET the current task's next actionable subtask (not started, no live session) from the Sprava IDE.
# env: $SPRAVA_PORT, $SPRAVA_PROJECT_ID, $SPRAVA_TASK_ID (present in Sprava IDE task terminals)
set -euo pipefail

if [ -z "${SPRAVA_PORT:-}" ] || [ -z "${SPRAVA_PROJECT_ID:-}" ]; then
  echo "get-next-task.sh: \$SPRAVA_PORT and \$SPRAVA_PROJECT_ID must be set (run inside a Sprava IDE terminal)" >&2
  exit 1
fi

TASK_ID="${SPRAVA_TASK_ID:-}"
TASK_ID="${TASK_ID%%:*}"
if [ -z "$TASK_ID" ]; then
  echo "get-next-task.sh: no task in context (\$SPRAVA_TASK_ID unset)" >&2
  exit 1
fi

BODY_OUT=$(mktemp)
trap 'rm -f "$BODY_OUT"' EXIT

HTTP_CODE=$(curl -sS -o "$BODY_OUT" -w '%{http_code}' \
  "http://localhost:$SPRAVA_PORT/api/projects/$SPRAVA_PROJECT_ID/tasks/$TASK_ID/subtasks/next")

cat "$BODY_OUT"

if [ "$HTTP_CODE" -ge 400 ]; then
  echo >&2
  echo "get-next-task.sh: IDE returned HTTP $HTTP_CODE" >&2
  exit 1
fi
