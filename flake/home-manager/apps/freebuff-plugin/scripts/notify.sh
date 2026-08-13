#!/bin/sh
# Send a herdr notification (useful as a "ping me when done" helper).
# Usage: notify.sh [title] [body]
. "$(dirname "$0")/common.sh"

title="${1:-Freebuff}"
body="${2:-}"

if ! in_herdr; then
  echo "notify.sh must run inside a herdr pane (HERDR_ENV=1)" >&2
  exit 1
fi

"$HERDR" notification show "$title" --body "$body" --sound request
