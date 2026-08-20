{
  pkgs,
  lib,
  ...
}: let
  rdpDir = "/home/aliyss/Documents/rdp";
  vpnDir = "/home/aliyss/Documents/vpn";
  rbwBin = "${pkgs.rbw}/bin/rbw";
  rdpScript = pkgs.writeShellScriptBin "rdp-launch" ''
    shopt -s nullglob

    # Resolve which RBW entry to use.
    if [ -n "$1" ]; then
      if [[ "$1" == /* ]] || [[ "$1" == ./* ]]; then
        # An existing env file was given explicitly.
        SELECTED_PATH="$1"
        if [ ! -f "$SELECTED_PATH" ]; then
          echo "Error: Profile $SELECTED_PATH not found"
          exit 1
        fi
        source "$SELECTED_PATH"
      else
        # Assumes the argument names an RBW entry directly.
        RBW_RDP_CONFIG="$1"
      fi
    fi

    if [ -z "$RBW_RDP_CONFIG" ]; then
      # Select from rbw directly, filtered to RDP entries.
      ENTRIES=$(DISPLAY= ${rbwBin} list --fields name,user 2>/dev/null | ${pkgs.gnugrep}/bin/grep "RDP")
      if [ -z "$ENTRIES" ]; then
        ${pkgs.libnotify}/bin/notify-send "RDP Error" "No RDP entries found in Bitwarden"
        exit 1
      fi

      SELECTED=$(printf "%s\n" "$ENTRIES" | ${pkgs.fzf}/bin/fzf --prompt="Select RDP Entry: ")
      if [ -z "$SELECTED" ]; then
        exit 1
      fi
      RBW_RDP_CONFIG=$(printf "%s\n" "$SELECTED" | ${pkgs.coreutils}/bin/cut -f1)
    fi

    echo "Fetching configuration from rbw for '$RBW_RDP_CONFIG'..."

    RBW_DATA=$(DISPLAY= ${rbwBin} get "$RBW_RDP_CONFIG" 2>/dev/null)
    if [ -n "$RBW_DATA" ]; then
      PASSWORD="$RBW_DATA"
    fi

    RBW_USER=$(DISPLAY= ${rbwBin} get "$RBW_RDP_CONFIG" --field username 2>/dev/null)
    if [ -n "$RBW_USER" ]; then
      USERNAME="$RBW_USER"
    else
      RBW_USER_FALLBACK=$(DISPLAY= ${rbwBin} list --fields name,user | ${pkgs.gnugrep}/bin/grep "^$RBW_RDP_CONFIG	" | ${pkgs.coreutils}/bin/cut -f2- 2>/dev/null)
      if [ -n "$RBW_USER_FALLBACK" ]; then
        USERNAME="$RBW_USER_FALLBACK"
      fi
    fi

    RBW_URL=$(DISPLAY= ${rbwBin} get "$RBW_RDP_CONFIG" --field uris 2>/dev/null || \
               DISPLAY= ${rbwBin} get "$RBW_RDP_CONFIG" --field url 2>/dev/null || \
               DISPLAY= ${rbwBin} get "$RBW_RDP_CONFIG" --field uri 2>/dev/null || \
               DISPLAY= ${rbwBin} get "$RBW_RDP_CONFIG" --field ip 2>/dev/null || \
               DISPLAY= ${rbwBin} get "$RBW_RDP_CONFIG" --field hostname 2>/dev/null)
    if [ -n "$RBW_URL" ]; then
      URL="$RBW_URL"
    fi

    # Optional VPN from the entry's "vpn" custom field.
    RBW_VPN_FIELD=$(DISPLAY= ${rbwBin} get "$RBW_RDP_CONFIG" --field vpn 2>/dev/null)
    if [ -z "$RBW_VPN_FIELD" ]; then
      RBW_VPN_FIELD=$(DISPLAY= ${rbwBin} get "$RBW_RDP_CONFIG" --field VPN 2>/dev/null)
    fi

    if [ -z "$VPN_CONFIG" ] && [ -n "$RBW_VPN_FIELD" ]; then
      # Map the RBW VPN name back to a vpn-launch directory by checking
      # each <vpnDir>/*/.env for the matching RBW_VPN_CONFIG.
      for d in "${vpnDir}"/*/; do
        if [ -f "$d/.env" ] && ${pkgs.gnugrep}/bin/grep -q "RBW_VPN_CONFIG=\"$RBW_VPN_FIELD\"" "$d/.env" 2>/dev/null; then
          VPN_CONFIG=$(basename "$d")
          break
        fi
      done
      # Fall back to directory name if it matches directly.
      if [ -z "$VPN_CONFIG" ] && [ -d "${vpnDir}/$RBW_VPN_FIELD" ]; then
        VPN_CONFIG="$RBW_VPN_FIELD"
      fi
      if [ -z "$VPN_CONFIG" ]; then
        echo "Warning: no VPN config directory matched field '$RBW_VPN_FIELD'"
      fi
    fi

    if [ -z "$URL" ] || [ -z "$USERNAME" ]; then
       echo "Error: URL or USERNAME not set for $RBW_RDP_CONFIG"
       sleep 3
       exit 1
    fi

    # Extract host and port from URL
    RDP_HOST="$URL"
    RDP_PORT=3389
    if echo "$URL" | ${pkgs.gnugrep}/bin/grep -q ':'; then
      RDP_HOST=$(echo "$URL" | ${pkgs.coreutils}/bin/cut -d: -f1)
      RDP_PORT=$(echo "$URL" | ${pkgs.coreutils}/bin/cut -d: -f2-)
    fi

    # Check if RDP port is reachable
    echo "Checking connectivity to $URL (port $RDP_PORT)..."
    if ! ${pkgs.netcat}/bin/nc -z -w 2 "$RDP_HOST" "$RDP_PORT" >/dev/null 2>&1; then
      if [ -n "$VPN_CONFIG" ]; then
        echo "Host $URL (port $RDP_PORT) is unreachable and VPN_CONFIG ($VPN_CONFIG) is set."
        echo "Launching VPN..."
        ${pkgs.libnotify}/bin/notify-send "RDP" "Host unreachable, launching VPN: $VPN_CONFIG"

        # We need to launch vpn-launch and wait for it.
        # Since the user needs to interact with the VPN (2FA, sudo),
        # we run it. vpn-launch will now background itself once it detects
        # "Initialization Sequence Completed".
        if ! VPN_BACKGROUND=1 vpn-launch "$VPN_CONFIG"; then
          echo "Error: VPN failed to connect."
          read -p "Press Enter to retry connection anyway or Ctrl+C to abort..."
        fi

        echo "Checking connectivity to $URL (port $RDP_PORT)..."
        for i in {1..20}; do
          if ${pkgs.netcat}/bin/nc -z -w 2 "$RDP_HOST" "$RDP_PORT" >/dev/null 2>&1; then
            echo " Connectivity established!"
            break
          fi
          echo -n "."
          sleep 1
        done
        echo ""

        if ! ${pkgs.netcat}/bin/nc -z -w 2 "$RDP_HOST" "$RDP_PORT" >/dev/null 2>&1; then
          echo "Error: Host $URL (port $RDP_PORT) still unreachable after starting VPN."
          read -p "Press Enter to try connecting anyway or Ctrl+C to abort..."
        fi
      else
        echo "Warning: Host $URL (port $RDP_PORT) is unreachable and no VPN_CONFIG is defined."
        read -p "Press Enter to try connecting anyway or Ctrl+C to abort..."
      fi
    fi

    if [ -z "$PASSWORD" ]; then
      if [ -t 0 ]; then
        echo "Connecting to $URL as $USERNAME"
        read -rs -p "Enter Password for $USERNAME: " PASSWORD
        echo ""
      else
        ${pkgs.libnotify}/bin/notify-send "RDP Error" "Password required but no TTY available for $RBW_RDP_CONFIG"
        exit 1
      fi
    else
      echo "Connecting to $URL as $USERNAME (using password from rbw)"
    fi

    # xfreerdp (X11/XWayland client) - best overall remote session quality.
    #
    # - +clipboard: bidirectional clipboard. Works, but has minor sync quirks
    #   over XWayland on Hyprland (same class of bug as Wine/Citrix/VirtualBox
    #   clipboards) - content may need a re-copy on the remote side.
    # - +dynamic-resolution +disp: window resizes push resolution updates to
    #   the remote desktop (Right-Shift+R to force refresh if it lags).
    # - /size:1920x1080: initial crisp session size.
    # - /wm-class:Freerdp: deterministic class for Hyprland window rules.
    #
    # Keep the clipse "-listen" watcher OFF while an RDP session runs: it
    # races the RDP clipboard handshake and hangs it (observed futex hang).
    LOG_FILE="${rdpDir}/freerdp-$(date +%s).log"
    nohup ${pkgs.freerdp}/bin/xfreerdp +clipboard +dynamic-resolution +disp /size:1920x1080 /wm-class:Freerdp /v:"$URL" /u:"$USERNAME" /p:"$PASSWORD" /cert:ignore /network:auto /relax-order-checks /audio-mode:0 >"$LOG_FILE" 2>&1 &
    sleep 0.5
    exit 0
  '';
in {
  home.packages = [
    pkgs.freerdp
    pkgs.netcat
    rdpScript
  ];

  home.activation.createRdpDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${rdpDir}"
  '';
}