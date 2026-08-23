#!/bin/sh
# Seed the Freebuff -> Herdr integration.
# 1. Seeds the agent-detection override (existing behavior).
# 2. Installs a PATH wrapper at ~/.local/bin/freebuff that spawns the lifecycle
#    watcher on every freebuff invocation (manual or plugin pane).
#
# Usage: setup.sh [--uninstall] [--help]
. "$(dirname "$0")/common.sh"
set -e

WRAPPER_SRC="${HERDR_PLUGIN_ROOT}/scripts/freebuff-wrapper.sh"
WRAPPER_DEST="${HOME}/.local/bin/freebuff"

install_wrapper() {
  mkdir -p "$(dirname "$WRAPPER_DEST")"

  sed "s|__PLUGIN_ROOT__|${HERDR_PLUGIN_ROOT}|g" "$WRAPPER_SRC" > "$WRAPPER_DEST"
  chmod +x "$WRAPPER_DEST"

  echo "Installed lifecycle wrapper at $WRAPPER_DEST"

  # Warn if ~/.local/bin isn't on PATH
  case ":${PATH}:" in
    *:"${HOME}/.local/bin":*) ;;
    *) echo "Warning: ${HOME}/.local/bin is not on your PATH. Add it to your shell rc file." >&2 ;;
  esac
}

uninstall_wrapper() {
  if [ -f "$WRAPPER_DEST" ]; then
    rm -f "$WRAPPER_DEST"
    echo "Removed $WRAPPER_DEST"
  else
    echo "No wrapper found at $WRAPPER_DEST"
  fi
}

case "${1:-}" in
  --uninstall)
    uninstall_wrapper
    ;;
  --help)
    echo "Usage: setup.sh [--uninstall]"
    echo "  (no args)  Install the freebuff -> herdr integration"
    echo "  --uninstall  Remove the PATH wrapper (agent detection config is left in place)"
    exit 0
    ;;
  *)
    ensure_agent_detection
    install_wrapper
    echo "Freebuff <-> Herdr integration ready."
    ;;
esac
