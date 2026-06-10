#!/bin/bash
curl -s -X POST "http://localhost:$SPRAVA_PORT/api/terminals/$SPRAVA_TERMINAL_ID/close"
