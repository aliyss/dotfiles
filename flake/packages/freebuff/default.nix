{
  pkgs,
  lib,
}:
let
  freebuffNpm = pkgs.buildNpmPackage {
    pname = "freebuff";
    version = "0.0.149";

    src = pkgs.fetchzip {
      url = "https://registry.npmjs.org/freebuff/-/freebuff-0.0.149.tgz";
      sha256 = "156nr7mxib2b0vl7cyzqab7r12ciw3kxbz3nkybdajx29b7wp2m7";
    };

    npmDeps = pkgs.fetchNpmDeps {
      src = ./.;
      hash = "sha256-wdmzWuNFTG7l3qG8J/jdXWagimGLInCQ6GZahX8mfWs=";
    };

    postPatch = ''
      cp ${./package-lock.json} package-lock.json
    '';

    dontNpmBuild = true;
    npmPackFlags = [ "--ignore-scripts" ];
  };
in
# The herdr freebuff plugin reports idle/working/blocked state through a
# detached watcher that it normally spawns from a wrapper at
# ~/.local/bin/freebuff. Because freebuff is installed here via Nix (its
# .nix-profile bin shadows that wrapper, and ~/.local/bin is not on PATH),
# that wrapper never runs when `freebuff` is launched directly in a pane.
# This shim reproduces the watcher spawn so a directly-launched `freebuff`
# is still identified by herdr, then execs the real runtime.
pkgs.writeShellScriptBin "freebuff" ''
  watcher=""

  # GitHub-managed install: ~/.config/herdr/plugins/github/freebuff.integration-<hash>
  for d in "$HOME/.config/herdr/plugins/github/freebuff.integration-"*; do
    if [ -x "$d/scripts/status-watcher.sh" ]; then
      watcher="$d/scripts/status-watcher.sh"
      break
    fi
  done

  # Locally linked install (herdr plugin link ...): ask herdr for the plugin root.
  if [ -z "$watcher" ]; then
    root=$("''${HERDR_BIN_PATH:-herdr}" plugin list --json --plugin freebuff.integration 2>/dev/null \
      | sed -n 's/.*"plugin_root"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    if [ -n "$root" ] && [ -x "$root/scripts/status-watcher.sh" ]; then
      watcher="$root/scripts/status-watcher.sh"
    fi
  fi

  if [ "''${HERDR_ENV:-}" = "1" ] && [ -n "''${HERDR_PANE_ID:-}" ] && [ -n "$watcher" ]; then
    sh "$watcher" "$$" "$HERDR_PANE_ID" >/dev/null 2>&1 &
  fi

  exec ${lib.getExe' freebuffNpm "freebuff"} "$@"
''
