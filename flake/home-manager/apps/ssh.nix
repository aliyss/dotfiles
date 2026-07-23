{
  pkgs,
  lib,
  ...
}: let
  sshDir = "/home/aliyss/Documents/ssh";
  sshScript = pkgs.writeShellScriptBin "ssh-launch" ''
    shopt -s nullglob
    FILES=(${sshDir}/*.env)

    if [ -n "$1" ]; then
      if [[ "$1" == /* ]]; then
        SELECTED_PATH="$1"
      else
        SELECTED_PATH="${sshDir}/$1"
      fi
      if [ ! -f "$SELECTED_PATH" ]; then
        SELECTED_PATH="''${SELECTED_PATH}.env"
      fi
      SELECTED=$(basename "$SELECTED_PATH")
    else
      if [ ''${#FILES[@]} -eq 0 ]; then
        ${pkgs.libnotify}/bin/notify-send "SSH Error" "No .env files found in ${sshDir}"
        exit 1
      fi
      SELECTED=$(for f in "''${FILES[@]}"; do basename "$f"; done | ${pkgs.fzf}/bin/fzf --prompt="Select SSH Profile: ")
      if [ -z "$SELECTED" ]; then
        exit 1
      fi
      SELECTED_PATH="${sshDir}/$SELECTED"
    fi

    if [ ! -f "$SELECTED_PATH" ]; then
      echo "Error: Profile $SELECTED_PATH not found"
      exit 1
    fi

    source "$SELECTED_PATH"

    if [ -n "$RBW_SSH_CONFIG" ]; then
      echo "Fetching configuration from rbw for '$RBW_SSH_CONFIG'..."

      RBW_DATA=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_SSH_CONFIG" 2>/dev/null)
      if [ -n "$RBW_DATA" ]; then
        PASSWORD="$RBW_DATA"
      fi

      RBW_USER=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_SSH_CONFIG" --field username 2>/dev/null)
      if [ -n "$RBW_USER" ]; then
        USERNAME="$RBW_USER"
      else
        RBW_USER_FALLBACK=$(DISPLAY= ${pkgs.rbw}/bin/rbw list --fields name,user | ${pkgs.gnugrep}/bin/grep "^$RBW_SSH_CONFIG	" | ${pkgs.coreutils}/bin/cut -f2- 2>/dev/null)
        if [ -n "$RBW_USER_FALLBACK" ]; then
          USERNAME="$RBW_USER_FALLBACK"
        fi
      fi

      RBW_HOST=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_SSH_CONFIG" --field uris 2>/dev/null || \
                  DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_SSH_CONFIG" --field url 2>/dev/null || \
                  DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_SSH_CONFIG" --field uri 2>/dev/null || \
                  DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_SSH_CONFIG" --field ip 2>/dev/null || \
                  DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_SSH_CONFIG" --field hostname 2>/dev/null)
      if [ -n "$RBW_HOST" ]; then
        HOST="$RBW_HOST"
      fi
    fi

    if [ -z "$HOST" ] || [ -z "$USERNAME" ]; then
       echo "Error: HOST or USERNAME not set in $SELECTED"
       sleep 3
       exit 1
    fi

    if [ -n "$PORT" ]; then
      PORT_OPT="-p $PORT"
    else
      PORT_OPT=""
    fi

    echo "Checking connectivity to $HOST..."
    if ! ping -c 1 -W 2 "$HOST" >/dev/null 2>&1; then
      if [ -n "$VPN_CONFIG" ]; then
        echo "Host $HOST is unreachable and VPN_CONFIG ($VPN_CONFIG) is set."
        echo "Launching VPN..."
        ${pkgs.libnotify}/bin/notify-send "SSH" "Host unreachable, launching VPN: $VPN_CONFIG"

        if ! VPN_BACKGROUND=1 vpn-launch "$VPN_CONFIG"; then
          echo "Error: VPN failed to connect."
          read -p "Press Enter to retry connection anyway or Ctrl+C to abort..."
        fi

        echo "Checking connectivity to $HOST..."
        for i in {1..20}; do
          if ping -c 1 -W 2 "$HOST" >/dev/null 2>&1; then
            echo " Connectivity established!"
            break
          fi
          echo -n "."
          ${pkgs.coreutils}/bin/stdbuf -oL echo "" >/dev/null 2>&1 || true
          sleep 1
        done
        echo ""

        if ! ping -c 1 -W 2 "$HOST" >/dev/null 2>&1; then
          echo "Error: Host $HOST still unreachable after starting VPN."
          read -p "Press Enter to try connecting anyway or Ctrl+C to abort..."
        fi
      else
        echo "Warning: Host $HOST is unreachable and no VPN_CONFIG is defined."
        read -p "Press Enter to try connecting anyway or Ctrl+C to abort..."
      fi
    fi

    if [ -z "$PASSWORD" ]; then
      if [ -t 0 ]; then
        echo "Connecting to $HOST as $USERNAME"
        read -rs -p "Enter Password for $USERNAME: " PASSWORD
        echo ""
      else
        ${pkgs.libnotify}/bin/notify-send "SSH Error" "Password required but no TTY available for $SELECTED"
        exit 1
      fi
    else
      echo "Connecting to $HOST as $USERNAME (using password from rbw)"
    fi

    SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    exec ${pkgs.sshpass}/bin/sshpass -p "$PASSWORD" ${pkgs.openssh}/bin/ssh $SSH_OPTS $PORT_OPT "$USERNAME@$HOST"
  '';
in {
  home.packages = [
    pkgs.sshpass
    sshScript
  ];

  home.activation.createSshDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${sshDir}"
  '';
}
