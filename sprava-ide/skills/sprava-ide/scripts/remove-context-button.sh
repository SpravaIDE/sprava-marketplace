#!/bin/bash
ID="$1"
if [ -z "$ID" ]; then
  echo "usage: remove-context-button.sh <id>" >&2
  exit 1
fi
curl -s -X DELETE "http://localhost:$SPRAVA_PORT/api/terminals/$SPRAVA_TERMINAL_ID/contextbuttons/$ID"
