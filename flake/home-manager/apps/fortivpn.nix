{
  pkgs,
  lib,
  ...
}: let
  notify = "${pkgs.libnotify}/bin/notify-send";
  xmllint = "${pkgs.libxml2}/bin/xmllint";
  vpnDir = "/home/aliyss/Documents/vpn";

  # Device-agnostic FortiClient VPN control. The profile name is discovered
  # (never hardcoded) in priority order:
  #   1. $FORTIVPN_PROFILE
  #   2. first name from `forticlient vpn list` (empty on the VPN-only build)
  #   3. the <name> parsed from ~/Documents/vpn/forticlient/*.xml
  # If nothing resolves, `fortivpn up` triggers the interactive fortivpn-import
  # picker to add a profile, then retries.
  fortivpn = pkgs.writeShellScriptBin "fortivpn" ''
    set -u
    NOTIFY="${notify}"
    XMLLINT="${xmllint}"
    VPN_DIR="${vpnDir}"

    # The native client's SAML flow is brokered by the tray; make sure it's up.
    ensure_tray() {
      if ! pgrep -x fortitray > /dev/null 2>&1; then
        # Start the tray detached (module's autostart may not fire on bare
        # Wayland compositors).
        nohup forticlient-tray > /dev/null 2>&1 &
        sleep 2
      fi
    }

    # Extract the tunnel <name> from an XML export.
    xml_profile_name() {
      "''${XMLLINT}" --xpath "string((//connection/name | //vpn/sslvpn//name)[1])" "$1" 2>/dev/null
    }

    # Resolve a profile name, or echo nothing (no hard failure).
    resolve_profile() {
      if [ -n "''${FORTIVPN_PROFILE:-}" ]; then
        echo "$FORTIVPN_PROFILE"
        return 0
      fi

      # 1) First visible name from `vpn list` (empty on the VPN-only build).
      local names
      names=$(''${FORTICLIENT_CMD:-forticlient} vpn list 2>/dev/null \
        | grep -vE "^VPNs:|^\\s*\\(No VPN|^\\s*$" \
        | sed -E 's/^\\s*[-*]?\\s*//' \
        | grep -v '^$' | head -1)
      if [ -n "$names" ]; then
        echo "$names"
        return 0
      fi

      # 2) Name parsed from an XML export in the forticlient dir.
      local xml name xmls
      xmls=$(ls "$VPN_DIR"/forticlient/*.xml 2>/dev/null | head -1)
      if [ -n "$xmls" ]; then
        name=$("''${XMLLINT}" --xpath "string((//connection/name | //vpn/sslvpn//name)[1])" "$xmls" 2>/dev/null)
        if [ -n "$name" ]; then
          echo "$name"
          return 0
        fi
      fi

      return 0
    }

    case "''${1:-}" in
      up|connect)
        PROFILE=$(resolve_profile)
        if [ -z "$PROFILE" ]; then
          # No known profile: try importing from the XML export(s) first.
          $NOTIFY "FortiClient" "No profile found; importing from XML..."
          fortivpn-import || exit 1
          PROFILE=$(resolve_profile)
        fi
        [ -n "$PROFILE" ] || {
          $NOTIFY "FortiClient" "No VPN profile available"
          exit 1
        }
        ensure_tray
        $NOTIFY "FortiClient" "Connecting to $PROFILE..."
        # Interactive: connecting drives the SAML browser. On success notify.
        if forticlient vpn connect "$PROFILE"; then
          $NOTIFY "FortiClient" "Connected to $PROFILE"
        else
          $NOTIFY "FortiClient" "Failed to connect to $PROFILE"
          exit 1
        fi
        ;;
      down|disconnect)
        PROFILE=$(resolve_profile)
        [ -n "$PROFILE" ] || exit 0
        forticlient vpn disconnect "$PROFILE" 2>/dev/null || forticlient vpn disconnect 2>/dev/null || true
        $NOTIFY "FortiClient" "Disconnected from $PROFILE"
        ;;
      status)
        forticlient vpn status
        ;;
      diag)
        # One-shot connectivity diagnostic. Target IP / corporate DNS are
        # overridable: FORTIPN_TARGET (default 10.30.100.196). Some checks need
        # root (ip xfrm, journalctl); those report "needs root" instead of failing.
        TARGET=''${FORTIVPN_TARGET:-10.30.100.196}
        echo "==== FortiClient diag (target $TARGET) ===="

        echo "-- FortiClient status --"
        forticlient vpn status 2>&1 | head -10

        echo "-- VPN/tunnel interfaces (want an ipsec dev + a 10.30.x addr) --"
        ip -br addr show 2>/dev/null | grep -E "10[\.]30[.]" || echo "  no 10.30.x address anywhere"
        ip link show 2>/dev/null | grep -E "^[0-9]+: (ipsec|tun|ppp)" || true

        echo "-- route to target --"
        ip route get "$TARGET" 2>&1

        echo "-- TCP $TARGET:22 --"
        if timeout 6 bash -c "cat < /dev/null > /dev/tcp/$TARGET/22" 2>/dev/null; then
          echo "  PORT 22 OPEN"
        else
          echo "  PORT 22 closed/unreachable"
        fi

        echo "-- ESP/xfrm SAs (needs root) --"
        if ip xfrm state 2>/dev/null | grep -q "^esp "; then
          echo "  IPsec SAs present:"
          ip xfrm state 2>/dev/null | grep -E "^esp |^aead " | head -8
        else
          echo "  no xfrm output (needs root or no SAs)"
        fi

        echo "-- last fctsched tunnel line (mode-config) --"
        journalctl --no-pager -u forticlient 2>/dev/null | grep -E "ikev2 .fctipsec. active tunnel" | tail -1 \
          | sed -E 's/.*active tunnel //' \
          | grep -oE "config (address|netmask|name-server|protected-subnet) [0-9.]+" | sort -u || true

        echo "-- verdict --"
        if ! forticlient vpn status 2>/dev/null | grep -qE "Status: Connected"; then
          echo "  NOT connected"
        elif ip route get "$TARGET" 2>/dev/null | grep -qE "via 192\.168\."; then
          echo "  PROBLEM: Connected, but target routes via home gateway => NO VPN route"
        else
          echo "  OK-ish: connected and target does NOT route via home gateway"
        fi
        ;;
      *)
        echo "usage: $0 {up|down|status|diag}" >&2
        exit 1
        ;;
    esac
  '';
in {
  home.packages = [
    fortivpn
    pkgs.libxml2
  ];
}