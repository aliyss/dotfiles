#!/bin/sh
# Launch Freebuff inside a herdr plugin PANE.
#
# Herdr runs plugin pane entrypoints as the pane's own PTY process, so freebuff
# gets a real TTY and its interactive TUI works. (Plugin actions/CLI have no TTY
# and cannot launch interactive agents, which is why these are panes, not actions.)
#
# Lifecycle state is reported by the wrapper at ~/.local/bin/freebuff, which is
# installed by setup.sh and spawns the detached status-watcher.sh on every
# freebuff invocation (manual or pane). If the wrapper is not installed, no
# lifecycle reporting occurs — run the setup action once.
#
# Usage: launch.sh <task|resume-last|resume-named> [session-id]
. "$(dirname "$0")/common.sh"

mode="${1:-task}"
name="${2:-}"

ensure_agent_detection

# Resolve freebuff binary.
# Prefer the wrapper at ~/.local/bin/freebuff (installed by setup.sh), which
# handles lifecycle watcher spawning. Fall back to command -v for dev setups
# that haven't run setup yet.
FREEBUFF_BIN="${FREEBUFF_BIN_PATH:-}"
if [ -z "$FREEBUFF_BIN" ]; then
  local_wrapper="${HOME}/.local/bin/freebuff"
  if [ -x "$local_wrapper" ]; then
    FREEBUFF_BIN="$local_wrapper"
  else
    FREEBUFF_BIN=$(command -v freebuff 2>/dev/null)
  fi
fi
if [ -z "$FREEBUFF_BIN" ] || [ ! -x "$FREEBUFF_BIN" ]; then
  echo "freebuff binary not found on PATH" >&2
  exit 1
fi

case "$mode" in
  task)
    exec "$FREEBUFF_BIN"
    ;;
  resume-last)
    exec "$FREEBUFF_BIN" --continue
    ;;
  resume-named)
    if [ -z "$name" ]; then
      name=$(printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" 2>/dev/null \
        | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{const j=JSON.parse(d);process.stdout.write(j.session_id||"")}catch{}})' 2>/dev/null)
    fi
    if [ -z "$name" ]; then
      echo "resume-named requires a session id (arg or context)" >&2
      exit 1
    fi
    exec "$FREEBUFF_BIN" --continue "$name"
    ;;
  *)
    echo "unknown launch mode: $mode" >&2
    exit 1
    ;;
esac
