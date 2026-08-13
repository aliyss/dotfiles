#!/bin/sh
# Freebuff -> Herdr lifecycle shim.
# Installed by setup.sh at ~/.local/bin/freebuff.
# Spawns the status watcher, then execs the real freebuff binary.
# The __PLUGIN_ROOT__ placeholder is replaced by setup.sh at install time.

PLUGIN_ROOT="__PLUGIN_ROOT__"

# Find the real freebuff binary by scanning PATH and skipping ourselves.
real_freebuff=""
OLDIFS="$IFS"
IFS=":"
for dir in $PATH; do
  IFS="$OLDIFS"
  [ -z "$dir" ] && continue
  candidate="$dir/freebuff"
  [ -x "$candidate" ] || continue
  [ "$candidate" -ef "$0" ] && continue
  real_freebuff="$candidate"
  break
done
IFS="$OLDIFS"

if [ -z "$real_freebuff" ]; then
  echo "freebuff shim: real freebuff binary not found on PATH" >&2
  exit 1
fi

# Spawn the lifecycle watcher in the background.
# Only when running inside a managed herdr pane.
if [ "${HERDR_ENV:-}" = "1" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
  sh "$PLUGIN_ROOT/scripts/status-watcher.sh" "$$" "$HERDR_PANE_ID" >/dev/null 2>&1 &
fi

exec "$real_freebuff" "$@"
