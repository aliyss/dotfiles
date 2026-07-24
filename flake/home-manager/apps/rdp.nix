{
  pkgs,
  lib,
  ...
}: let
  rdpDir = "/home/aliyss/Documents/rdp";
  rdpScript = pkgs.writeShellScriptBin "rdp-launch" ''
    shopt -s nullglob
    FILES=(${rdpDir}/*.env)

    if [ -n "$1" ]; then
      if [[ "$1" == /* ]]; then
        SELECTED_PATH="$1"
      else
        SELECTED_PATH="${rdpDir}/$1"
      fi
      if [ ! -f "$SELECTED_PATH" ]; then
        SELECTED_PATH="''${SELECTED_PATH}.env"
      fi
      SELECTED=$(basename "$SELECTED_PATH")
    else
      if [ ''${#FILES[@]} -eq 0 ]; then
        ${pkgs.libnotify}/bin/notify-send "RDP Error" "No .env files found in ${rdpDir}"
        exit 1
      fi
      SELECTED=$(for f in "''${FILES[@]}"; do basename "$f"; done | ${pkgs.fzf}/bin/fzf --prompt="Select RDP Profile: ")
      if [ -z "$SELECTED" ]; then
        exit 1
      fi
      SELECTED_PATH="${rdpDir}/$SELECTED"
    fi

    if [ ! -f "$SELECTED_PATH" ]; then
      echo "Error: Profile $SELECTED_PATH not found"
      exit 1
    fi

    source "$SELECTED_PATH"

    if [ -n "$RBW_RDP_CONFIG" ]; then
      echo "Fetching configuration from rbw for '$RBW_RDP_CONFIG'..."

      RBW_DATA=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_RDP_CONFIG" 2>/dev/null)
      if [ -n "$RBW_DATA" ]; then
        PASSWORD="$RBW_DATA"
      fi

      RBW_USER=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_RDP_CONFIG" --field username 2>/dev/null)
      if [ -n "$RBW_USER" ]; then
        USERNAME="$RBW_USER"
      else
        RBW_USER_FALLBACK=$(DISPLAY= ${pkgs.rbw}/bin/rbw list --fields name,user | ${pkgs.gnugrep}/bin/grep "^$RBW_RDP_CONFIG	" | ${pkgs.coreutils}/bin/cut -f2- 2>/dev/null)
        if [ -n "$RBW_USER_FALLBACK" ]; then
          USERNAME="$RBW_USER_FALLBACK"
        fi
      fi

      RBW_URL=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_RDP_CONFIG" --field uris 2>/dev/null || \
                DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_RDP_CONFIG" --field url 2>/dev/null || \
                DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_RDP_CONFIG" --field uri 2>/dev/null || \
                DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_RDP_CONFIG" --field ip 2>/dev/null || \
                DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_RDP_CONFIG" --field hostname 2>/dev/null)
      if [ -n "$RBW_URL" ]; then
        URL="$RBW_URL"
      fi
    fi

    if [ -z "$URL" ] || [ -z "$USERNAME" ]; then
       echo "Error: URL or USERNAME not set in $SELECTED"
       sleep 3
       exit 1
    fi

    # Check if host is reachable
    echo "Checking connectivity to $URL..."
    if ! ping -c 1 -W 2 "$URL" >/dev/null 2>&1; then
      if [ -n "$VPN_CONFIG" ]; then
        echo "Host $URL is unreachable and VPN_CONFIG ($VPN_CONFIG) is set."
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

        echo "Checking connectivity to $URL..."
        for i in {1..20}; do
          if ping -c 1 -W 2 "$URL" >/dev/null 2>&1; then
            echo " Connectivity established!"
            break
          fi
          echo -n "."
          ${pkgs.coreutils}/bin/stdbuf -oL echo "" >/dev/null 2>&1 || true
          sleep 1
        done
        echo ""

        if ! ping -c 1 -W 2 "$URL" >/dev/null 2>&1; then
          echo "Error: Host $URL still unreachable after starting VPN."
          read -p "Press Enter to try connecting anyway or Ctrl+C to abort..."
        fi
      else
        echo "Warning: Host $URL is unreachable and no VPN_CONFIG is defined."
        read -p "Press Enter to try connecting anyway or Ctrl+C to abort..."
      fi
    fi

    if [ -z "$PASSWORD" ]; then
      if [ -t 0 ]; then
        echo "Connecting to $URL as $USERNAME"
        read -rs -p "Enter Password for $USERNAME: " PASSWORD
        echo ""
      else
        ${pkgs.libnotify}/bin/notify-send "RDP Error" "Password required but no TTY available for $SELECTED"
        exit 1
      fi
    else
      echo "Connecting to $URL as $USERNAME (using password from rbw)"
    fi

    # Using xfreerdp (X11 client) which is stable on XWayland.
    # The correct syntax for this version of FreeRDP is /kbd:layout:<id>,unicode:on
    # We use 0x00000807 (Swiss German) as the layout and enable unicode for your custom symbols.
    nohup ${pkgs.freerdp}/bin/xfreerdp /v:"$URL" /u:"$USERNAME" /p:"$PASSWORD" /dynamic-resolution /cert:ignore /network:auto /relax-order-checks /audio-mode:0 >/dev/null 2>&1 &
    # nohup ${pkgs.freerdp}/bin/xfreerdp /v:"$URL" /u:"$USERNAME" /p:"$PASSWORD" /dynamic-resolution /kbd:unicode:on /cert:ignore /network:auto /relax-order-checks /audio-mode:0 >/dev/null 2>&1 &
    sleep 0.5
    exit 0
  '';
in {
  home.packages = [
    pkgs.freerdp
    rdpScript
  ];

  home.activation.createRdpDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${rdpDir}"
  '';
}
