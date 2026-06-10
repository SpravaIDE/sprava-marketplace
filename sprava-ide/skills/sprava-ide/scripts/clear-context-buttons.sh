#!/bin/bash
curl -s -X DELETE "http://localhost:$SPRAVA_PORT/api/terminals/$SPRAVA_TERMINAL_ID/contextbuttons"
