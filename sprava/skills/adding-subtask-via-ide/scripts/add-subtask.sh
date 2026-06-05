#!/bin/bash
# POST a composed subtask to the Sprava IDE add-subtask endpoint.
# The IDE numbers the subtask, places the block, persists to-do.md, and syncs the
# checklist source of truth. This script only carries the HTTP hop.
#
# usage: add-subtask.sh --issue <ISSUE_ID> --title <TITLE> --body-file <PATH> [--parent <PARENT_SUBTASK_ID>]
#   --issue       issue id only (e.g. CHECKLIST-MANAGEMENT) — NOT the composite SPRAVA_TASK_ID
#   --title       one-line subtask title (no heading / id — the IDE renders the heading)
#   --body-file   path to a file holding the subtask body (context paragraph + checklist)
#   --parent      effective parent subtask id; omit (or pass "") for a top-level subtask
# env: $SPRAVA_PORT, $SPRAVA_PROJECT_ID (present in Sprava IDE terminals)
set -euo pipefail

ISSUE=""
TITLE=""
BODY_FILE=""
PARENT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --issue) ISSUE="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --body-file) BODY_FILE="$2"; shift 2 ;;
    --parent) PARENT="$2"; shift 2 ;;
    *) echo "add-subtask.sh: unknown argument '$1'" >&2; exit 1 ;;
  esac
done

if [ -z "$ISSUE" ] || [ -z "$TITLE" ] || [ -z "$BODY_FILE" ]; then
  echo "usage: add-subtask.sh --issue <ISSUE_ID> --title <TITLE> --body-file <PATH> [--parent <PARENT_SUBTASK_ID>]" >&2
  exit 1
fi

if [ -z "${SPRAVA_PORT:-}" ] || [ -z "${SPRAVA_PROJECT_ID:-}" ]; then
  echo "add-subtask.sh: \$SPRAVA_PORT and \$SPRAVA_PROJECT_ID must be set (run inside a Sprava IDE terminal)" >&2
  exit 1
fi

if [ ! -f "$BODY_FILE" ]; then
  echo "add-subtask.sh: body file not found: $BODY_FILE" >&2
  exit 1
fi

PAYLOAD=$(jq -n \
  --arg title "$TITLE" \
  --arg parent "$PARENT" \
  --rawfile body "$BODY_FILE" \
  '{title: $title, body: $body} + (if $parent == "" then {} else {parentSubtaskId: $parent} end)')

BODY_OUT=$(mktemp)
trap 'rm -f "$BODY_OUT"' EXIT

HTTP_CODE=$(curl -sS -o "$BODY_OUT" -w '%{http_code}' -X POST \
  "http://localhost:$SPRAVA_PORT/api/projects/$SPRAVA_PROJECT_ID/tasks/$ISSUE/subtasks" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

cat "$BODY_OUT"

if [ "$HTTP_CODE" -ge 400 ]; then
  echo >&2
  echo "add-subtask.sh: IDE returned HTTP $HTTP_CODE" >&2
  exit 1
fi
