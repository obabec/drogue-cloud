#!/usr/bin/env bash

set -e
set -x
set -o pipefail

: "${API_URL:=http://localhost:8011}"

echo "Setting backend endpoint:"

echo '{}' | jq --arg url "$API_URL" '. + {url: $url}' | tee /endpoints/backend.json

LOGIN_NOTE=/etc/config/login/note.html
if [ -f "$LOGIN_NOTE" ]; then
  echo "Adding login note: $LOGIN_NOTE"
  jq --arg note "$(cat "$LOGIN_NOTE")" '. + {login_note: $note}' < /endpoints/backend.json | tee /endpoints/backend.json.tmp
  mv /endpoints/backend.json.tmp /endpoints/backend.json
else
  echo "Skipping login note: $LOGIN_NOTE"
fi

echo "Final backend information:"
echo "---"
cat /endpoints/backend.json
echo "---"

jq --arg url "$BACKEND_URL" '. + {url: $url}' < /ui-config.template.json | tee /endpoints/ui-config.json

echo "Final Swagger UI config:"
echo "---"
cat /endpoints/ui-config.json
echo "---"

exec /usr/sbin/nginx -g "daemon off;"
