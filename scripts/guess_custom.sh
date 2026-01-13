#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
  echo "Usage: $0 <room_id> <shape> <colour> <pattern> <direction>"
  echo "Example: $0 abc-123 circle red vertical_stripes top"
  exit 1
fi

ROOM_ID="$1"
SHAPE="$2"
COLOUR="$3"
PATTERN="$4"
DIRECTION="$5"

curl -X POST "http://localhost:4000/api/games/$ROOM_ID/guess" \
  -H "Content-Type: application/json" \
  -d "{\"guess\": {\"shape\": \"$SHAPE\", \"colour\": \"$COLOUR\", \"pattern\": \"$PATTERN\", \"direction\": \"$DIRECTION\"}}"
