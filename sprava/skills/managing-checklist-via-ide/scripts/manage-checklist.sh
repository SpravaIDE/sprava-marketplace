#!/bin/bash
# Manage a task's checklist via the Sprava IDE checklist-write endpoints. The IDE rewrites the
# to-do.md cache under a per-task lock and, when a checklist-source plugin owns the task, pushes the
# whole checklist to the source of truth (the YouTrack issue description) and reconciles the cache.
# This script only carries the HTTP hop.
#
# usage:
#   manage-checklist.sh update-subtask --issue <ISSUE_ID> --subtask <SUBTASK_ID> --content-file <PATH>
#   manage-checklist.sh toggle         --issue <ISSUE_ID> --subtask <SUBTASK_ID> \
#                                       --item-text <TEXT> --item-index <N> --checked <true|false>
#   manage-checklist.sh set-checklist  --issue <ISSUE_ID> --content-file <PATH>
#
#   --issue         issue id only (e.g. CHECKLIST-MANAGEMENT) — NOT the composite SPRAVA_TASK_ID
#   --subtask       subtask id as it appears in to-do.md (e.g. P-9)
#   --content-file  path to a file holding the markdown (subtask block, or whole checklist)
#   --item-text     the checklist item's text, exactly as written after the checkbox
#   --item-index    0-based position of the item among the subtask's direct checkboxes (tie-break)
#   --checked       true to check the box, false to uncheck
# env: $SPRAVA_PORT, $SPRAVA_PROJECT_ID (present in Sprava IDE terminals)
set -euo pipefail

ISSUE=""
SUBTASK=""
CONTENT_FILE=""
ITEM_TEXT=""
ITEM_INDEX=""
CHECKED=""

if [ $# -eq 0 ]; then
  echo "manage-checklist.sh: missing subcommand (update-subtask | toggle | set-checklist)" >&2
  exit 1
fi
OP="$1"
shift

while [ $# -gt 0 ]; do
  case "$1" in
    --issue) ISSUE="$2"; shift 2 ;;
    --subtask) SUBTASK="$2"; shift 2 ;;
    --content-file) CONTENT_FILE="$2"; shift 2 ;;
    --item-text) ITEM_TEXT="$2"; shift 2 ;;
    --item-index) ITEM_INDEX="$2"; shift 2 ;;
    --checked) CHECKED="$2"; shift 2 ;;
    *) echo "manage-checklist.sh: unknown argument '$1'" >&2; exit 1 ;;
  esac
done

if [ -z "${SPRAVA_PORT:-}" ] || [ -z "${SPRAVA_PROJECT_ID:-}" ]; then
  echo "manage-checklist.sh: \$SPRAVA_PORT and \$SPRAVA_PROJECT_ID must be set (run inside a Sprava IDE terminal)" >&2
  exit 1
fi

BASE="http://localhost:$SPRAVA_PORT/api/projects/$SPRAVA_PROJECT_ID/tasks"

# request <METHOD> <URL> <JSON_PAYLOAD>: print the IDE response body, exit non-zero on HTTP >= 400.
request() {
  local method="$1" url="$2" payload="$3"
  local body_out http_code
  body_out=$(mktemp)
  trap 'rm -f "$body_out"' RETURN

  http_code=$(curl -sS -o "$body_out" -w '%{http_code}' -X "$method" "$url" \
    -H "Content-Type: application/json" \
    -d "$payload")

  cat "$body_out"

  if [ "$http_code" -ge 400 ]; then
    echo >&2
    echo "manage-checklist.sh: IDE returned HTTP $http_code" >&2
    return 1
  fi
}

require_content_file() {
  if [ -z "$CONTENT_FILE" ]; then
    echo "manage-checklist.sh: $OP requires --content-file" >&2
    exit 1
  elif [ ! -f "$CONTENT_FILE" ]; then
    echo "manage-checklist.sh: content file not found: $CONTENT_FILE" >&2
    exit 1
  fi
}

case "$OP" in
  update-subtask)
    if [ -z "$ISSUE" ] || [ -z "$SUBTASK" ]; then
      echo "manage-checklist.sh: update-subtask requires --issue and --subtask" >&2
      exit 1
    fi
    require_content_file
    PAYLOAD=$(jq -n --rawfile content "$CONTENT_FILE" '{content: $content}')
    request PUT "$BASE/$ISSUE/subtasks/$SUBTASK" "$PAYLOAD"
    ;;

  toggle)
    if [ -z "$ISSUE" ] || [ -z "$SUBTASK" ] || [ -z "$ITEM_TEXT" ] || [ -z "$ITEM_INDEX" ] || [ -z "$CHECKED" ]; then
      echo "manage-checklist.sh: toggle requires --issue --subtask --item-text --item-index --checked" >&2
      exit 1
    fi
    PAYLOAD=$(jq -n \
      --arg subtaskId "$SUBTASK" \
      --arg itemText "$ITEM_TEXT" \
      --argjson itemIndex "$ITEM_INDEX" \
      --argjson checked "$CHECKED" \
      '{locator: {subtaskId: $subtaskId, itemText: $itemText, itemIndex: $itemIndex}, checked: $checked}')
    request POST "$BASE/$ISSUE/checklist/toggle" "$PAYLOAD"
    ;;

  set-checklist)
    if [ -z "$ISSUE" ]; then
      echo "manage-checklist.sh: set-checklist requires --issue" >&2
      exit 1
    fi
    require_content_file
    PAYLOAD=$(jq -n --rawfile content "$CONTENT_FILE" '{content: $content}')
    request PUT "$BASE/$ISSUE/checklist" "$PAYLOAD"
    ;;

  *)
    echo "manage-checklist.sh: unknown subcommand '$OP' (expected update-subtask | toggle | set-checklist)" >&2
    exit 1
    ;;
esac
