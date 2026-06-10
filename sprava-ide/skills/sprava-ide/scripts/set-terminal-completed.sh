#!/bin/bash
COMPLETED="${1:-true}"
curl -s -X POST "http://localhost:$SPRAVA_PORT/api/terminals/$SPRAVA_TERMINAL_ID/completed" \
  -H "Content-Type: application/json" \
  -d "{\"completed\": $COMPLETED}"
