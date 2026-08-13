#!/bin/sh
# Shared helpers for the Freebuff herdr plugin.
# Sourced by the launch/notify/setup scripts. Safe to source outside herdr (no-ops).

: "${HERDR_BIN_PATH:=herdr}"
HERDR="$HERDR_BIN_PATH"
PANE_ID="${HERDR_PANE_ID:-}"

# Plugin root: herdr provides this for plugin actions; fall back to this
# script's own location so setup works when invoked directly.
: "${HERDR_PLUGIN_ROOT:=$(cd "$(dirname "$0")/.." && pwd)}"

# True when running inside a managed herdr pane.
in_herdr() { [ "${HERDR_ENV:-}" = "1" ]; }

# Seed the freebuff agent-detection override into herdr's config dir (once).
# Herdr loads local overrides from $HERDR_PLUGIN_CONFIG_DIR/agent-detection/.
ensure_agent_detection() {
  if ! in_herdr; then return 0; fi
  src="${HERDR_PLUGIN_ROOT}/config/agent-detection/freebuff.toml"
  if [ -n "${HERDR_PLUGIN_CONFIG_DIR:-}" ] && [ -f "$src" ]; then
    dest_dir="${HERDR_PLUGIN_CONFIG_DIR}/agent-detection"
    mkdir -p "$dest_dir"
    dest="${dest_dir}/freebuff.toml"
    if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest"; then
      cp "$src" "$dest"
    fi
  fi
}
