#!/bin/sh
# Freebuff -> Herdr lifecycle status watcher.
#
# Spawned as a detached child of scripts/launch.sh. Scans freebuff's per-chat
# state files across ALL manicode projects (~/.config/manicode/projects/*/chats/)
# to classify the agent state and reports to the herdr pane socket.
#
# Arguments: <launcher_pid> <pane_id>

. "$(dirname "$0")/watcher-lib.sh"

PANE_ID="$2"
LAUNCHER_PID="$1"

[ "${HERDR_ENV:-}" = "1" ] && [ -n "$PANE_ID" ] || exit 0

# Monotonic seq counter (mirrors opencode's reportSeq pattern)
SEQ_FILE="${TMPDIR:-/tmp}/herdr-freebuff-seq-${PANE_ID}"
next_seq() {
  if [ -f "$SEQ_FILE" ]; then
    seq=$(cat "$SEQ_FILE" 2>/dev/null | tr -dc '0-9')
  else
    seq=$(node -e 'process.stdout.write(String(Date.now()*1000))')
  fi
  seq=$(( ${seq:-0} + 1 ))
  printf '%s' "$seq" > "$SEQ_FILE"
  printf '%s' "$seq"
}

report() {
  "$(herdr_cmd)" pane report-agent "$PANE_ID" \
    --source freebuff --agent freebuff --state "$1" --seq "$(next_seq)" >/dev/null 2>&1
}

label() {
  "$(herdr_cmd)" pane report-metadata "$PANE_ID" \
    --source freebuff --agent freebuff --display-agent freebuff >/dev/null 2>&1
}

# --- Main loop ---
label

PREV_STATE=""

while kill -0 "$LAUNCHER_PID" 2>/dev/null; do
  chat_dir=$(find_newest_chat)

  if [ -z "$chat_dir" ]; then
    [ "$PREV_STATE" != "idle" ] && report idle
    PREV_STATE="idle"
    sleep 0.7
    continue
  fi

  state=$(classify "$chat_dir" "$PANE_ID")

  [ "$state" != "$PREV_STATE" ] && {
    report "$state"
    PREV_STATE="$state"
  }

  sleep 0.7
done
