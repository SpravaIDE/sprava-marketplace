#!/bin/bash
LABEL="$1"
curl -s -X POST "http://localhost:$SPRAVA_PORT/api/terminals/$SPRAVA_TERMINAL_ID/label" \
  -H "Content-Type: application/json" \
  -d "{\"label\": \"$LABEL\"}"
