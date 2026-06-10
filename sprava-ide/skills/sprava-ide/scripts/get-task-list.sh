#!/bin/bash
# GET the project's task list (id, title, status, progress) from the Sprava IDE.
# usage: get-task-list.sh [search] [statuses] [limit]
#   search   — substring match over task id and title (optional, "" to skip)
#   statuses — comma-separated status filter, e.g. "new,in-progress" (optional, "" to skip)
#   limit    — max tasks returned (optional, default 10; response total reports the full match count)
# env: $SPRAVA_PORT, $SPRAVA_PROJECT_ID (present in Sprava IDE task terminals)
set -euo pipefail

if [ -z "${SPRAVA_PORT:-}" ] || [ -z "${SPRAVA_PROJECT_ID:-}" ]; then
  echo "get-task-list.sh: \$SPRAVA_PORT and \$SPRAVA_PROJECT_ID must be set (run inside a Sprava IDE terminal)" >&2
  exit 1
fi

SEARCH="${1:-}"
STATUSES="${2:-}"
LIMIT="${3:-10}"

QUERY_ARGS=(--data-urlencode "summary=true" --data-urlencode "limit=$LIMIT")
if [ -n "$SEARCH" ]; then
  QUERY_ARGS+=(--data-urlencode "search=$SEARCH")
fi
if [ -n "$STATUSES" ]; then
  QUERY_ARGS+=(--data-urlencode "statuses=$STATUSES")
fi

BODY_OUT=$(mktemp)
trap 'rm -f "$BODY_OUT"' EXIT

HTTP_CODE=$(curl -sS -G -o "$BODY_OUT" -w '%{http_code}' "${QUERY_ARGS[@]}" \
  "http://localhost:$SPRAVA_PORT/api/projects/$SPRAVA_PROJECT_ID/tasks")

cat "$BODY_OUT"

if [ "$HTTP_CODE" -ge 400 ]; then
  echo >&2
  echo "get-task-list.sh: IDE returned HTTP $HTTP_CODE" >&2
  exit 1
fi
