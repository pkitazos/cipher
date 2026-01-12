#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <room_id>"
  exit 1
fi

ROOM_ID="$1"

curl -X POST "http://localhost:4000/api/games/$ROOM_ID/guess" \
  -H "Content-Type: application/json" \
  -d '{"guess": {"shape": "circle", "colour": "red", "pattern": "vertical_stripes", "direction": "top"}}'
