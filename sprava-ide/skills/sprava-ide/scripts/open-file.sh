#!/bin/bash
MODE="tab"
if [ "$1" = "--split" ]; then
  MODE="split"
  shift
fi
TASK_ID_JSON="null"
if [ -n "$SPRAVA_TASK_ID" ]; then
  TASK_ID_JSON="\"$SPRAVA_TASK_ID\""
fi
TERMINAL_ID_JSON="null"
if [ -n "$SPRAVA_TERMINAL_ID" ]; then
  TERMINAL_ID_JSON="\"$SPRAVA_TERMINAL_ID\""
fi
curl -s -X POST "http://localhost:$SPRAVA_PORT/api/projects/$SPRAVA_PROJECT_ID/openfile" \
  -H "Content-Type: application/json" \
  -d "{\"filePath\": \"$1\", \"lineNumber\": ${2:-null}, \"mode\": \"$MODE\", \"taskId\": $TASK_ID_JSON, \"terminalId\": $TERMINAL_ID_JSON}"
