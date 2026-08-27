{
  pkgs,
  lib,
  ...
}: let
  notify = "${pkgs.libnotify}/bin/notify-send";
  xmllint = "${pkgs.libxml2}/bin/xmllint";
  fzf = "${pkgs.fzf}/bin/fzf";
  forticlient = "forticlient";
  vpnDir = "/home/aliyss/Documents/vpn";

  # Import VPN profile(s) from FortiClient config XML exports by driving the
  # interactive `forticlient vpn edit` CLI. The CLI wizard only understands
  # SSL-VPN style profiles (gateway / port / auth / cert type), so any IPsec
  # extras (preshared key, proposals, dhgroup) stay encrypted in the XML and do
  # NOT carry across — same limitation as `vpn edit` itself.
  fortivpnImport = pkgs.writeShellScriptBin "fortivpn-import" ''
    set -u
    NOTIFY="${notify}"
    XMLLINT="${xmllint}"
    FZF="${fzf}"
    VPN_DIR="${vpnDir}"

    # Extract a field from the current $XML (defensively, SSL/IPsec layouts).
    xpath_first() {
      local expr="$1"
      "$XMLLINT" --xpath "string(($expr)[1])" "$XML" 2>/dev/null
    }

    # `vpn list` is empty on the VPN-only build even when profiles exist, so
    # check existence via `vpn view <name>` instead.
    profile_exists() {
      ${forticlient} vpn view "$1" 2>/dev/null | grep -qE "^VPN: $1([[:space:]]|$)"
    }

    # Import a single profile. $XML must be set; NAME/GATEWAY may be pre-set by
    # the caller (single-file mode), otherwise they're derived from the XML.
    import_one() {
      local NAME=''${1:-}
      local GATEWAY=''${2:-}
      local PORT AUTH CERT

      [ -f "$XML" ] || {
        echo "skip: $XML (no such file)" >&2
        return 1
      }

      if [ -z "$NAME" ]; then
        NAME=$(xpath_first "//connection/name | //vpn/sslvpn//name")
        [ -z "$NAME" ] && NAME=$(xpath_first "//*[local-name()='name']")
        [ -z "$NAME" ] && NAME=$(basename "$XML" .xml)
      fi
      if [ -z "$GATEWAY" ]; then
        # Try gateway XPaths in priority order; a document-order union can
        # land on an unrelated, empty <server/> earlier in the file.
        local gp
        for gp in "//ike_settings/server" "//sslvpn/connection/server" "//sslvpn/assigned_name" "//connection/server"; do
          GATEWAY=$(xpath_first "$gp")
          [ -n "$GATEWAY" ] && break
        done
      fi
      PORT=$(xpath_first "//ike_settings/tcp_port | //sslvpn/connection/port")

      if profile_exists "$NAME"; then
        echo "skip: '$NAME' already exists" >&2
        return 0
      fi

      echo "Importing profile: $NAME"
      if [ -n "$GATEWAY" ]; then
        echo "  gateway: $GATEWAY"
      else
        read -rp "  Remote Gateway (e.g. vpn.example.com): " GATEWAY || return 1
      fi
      if [ -z "$PORT" ]; then
        read -rp "  Port [default=443]: " PORT
        [ -z "$PORT" ] && PORT=443
      fi

      if [ -n "''${3:-}" ] && [ -n "''${4:-}" ]; then
        AUTH=''${3:-}
        CERT=''${4:-}
      else
        read -rp "  Authentication (1.prompt / 2.save / 3.disable) [default=1]: " AUTH
        [ -z "$AUTH" ] && AUTH=1
        read -rp "  Certificate Type (1.local(pkcs12) / 2.smartcard / 3.disable) [default=3]: " CERT
        [ -z "$CERT" ] && CERT=3
      fi

      # Drive the interactive vpn edit wizard with the collected answers.
      printf '%s\n%s\n%s\n%s\n' "$GATEWAY" "$PORT" "$AUTH" "$CERT" \
        | ${forticlient} vpn edit "$NAME"

      if profile_exists "$NAME"; then
        $NOTIFY "Fortivpn-import" "Imported '$NAME' ($GATEWAY)"
        echo "  imported: '$NAME'"
      else
        $NOTIFY "Fortivpn-import" "Import of '$NAME' may have failed"
        echo "  FAILED: '$NAME'" >&2
        return 1
      fi
    }

    usage() {
      echo "usage: $0 <profile.xml> [--name NAME] [--gateway HOST[:PORT]]" >&2
      echo "   or: $0 --all  [--auth N] [--cert N]" >&2
      echo "          fzf multi-select over *.xml under $VPN_DIR/forticlient" >&2
      echo "          (existing profiles are skipped)" >&2
      echo "       With no file argument, falls back to the --all picker if any .xml exist." >&2
      exit 1
    }

    MODE="single"
    XML=""
    NAME=""
    GATEWAY=""
    ALL_AUTH=""
    ALL_CERT=""

    # Parse args (XML path handled as bare positional).
    while [ $# -gt 0 ]; do
      case "$1" in
        --all) MODE="all" ; shift ;;
        --auth) ALL_AUTH="$2"; shift 2 ;;
        --cert) ALL_CERT="$2"; shift 2 ;;
        --name) NAME="$2"; shift 2 ;;
        --gateway) GATEWAY="$2"; shift 2 ;;
        * ) [ -z "$XML" ] && XML="$1" ; shift ;;
      esac
    done

    if [ "$MODE" = "all" ] || [ -z "$XML" ]; then
      # Gather every profile XML from the forticlient dir (the canonical home
      # for FortiClient XML exports).
      mapfile -t FILES < <(ls "$VPN_DIR"/forticlient/*.xml 2>/dev/null)
      if [ ''${#FILES[@]} -eq 0 ]; then
        $NOTIFY "Fortivpn-import" "No *.xml found in $VPN_DIR/forticlient"
        echo "No *.xml found in $VPN_DIR/forticlient" >&2
        exit 1
      fi

      echo "Select profiles to import:"
      mapfile -t SELECTED < <(printf '%s\n' "''${FILES[@]}" | "$FZF" --multi \
        --prompt="Import VPN profiles: ")
      [ ''${#SELECTED[@]} -eq 0 ] && echo "aborted" && exit 0

      NA=0 NF=0
      for XML in "''${SELECTED[@]}"; do
        if import_one "" "" "$ALL_AUTH" "$ALL_CERT"; then
          NA=$((NA+1))
        else
          NF=$((NF+1))
        fi
      done
      $NOTIFY "Fortivpn-import" "Done: $NA imported, $NF failed/skipped"
      exit 0
    fi

    # Single-file mode.
    [ -n "$XML" ] || usage
    import_one "$NAME" "$GATEWAY"
  '';
in {
  home.packages = [
    fortivpnImport
    pkgs.libxml2
  ];
}