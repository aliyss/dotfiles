{
  pkgs,
  lib,
  ...
}: let
  vpnDir = "/home/aliyss/Documents/vpn";

  vpnWgauth = pkgs.writeScript "vpn-wgauth" ''
    #!${pkgs.expect}/bin/expect -f
    set timeout 120
    set ovpn_conf [lindex $argv 0]
    set rbw_user [lindex $argv 1]
    set rbw_pass [lindex $argv 2]
    set mode [lindex $argv 3]

    if {$mode == "background"} {
        set sudo_pass_file $env(SUDO_PASS_FILE)
        set fh [open $sudo_pass_file r]
        set sudo_pass [string trim [read -nonewline $fh]]
        close $fh

        spawn sudo -S ${pkgs.openvpn}/bin/openvpn --config $ovpn_conf
        expect {
            "password for" {
                send "$sudo_pass\r"
                exp_continue
            }
            "Enter Auth Username:" {
                send "$rbw_user\r"
                exp_continue
            }
            "Enter Auth Password:" {
                send "$rbw_pass\r"
                exp_continue
            }
            "CHALLENGE:" {
                send "p\r"
                exp_continue
            }
            "Initialization Sequence Completed" {
                puts "VPN_ISC_REACHED"
                flush stdout
                set timeout -1
                vwait forever
            }
            "FATAL:" {
                exit 1
            }
            timeout {
                exit 1
            }
            eof {
                exit 0
            }
        }
    } else {
        spawn sudo ${pkgs.openvpn}/bin/openvpn --config $ovpn_conf
        expect {
            "password for" {
                interact -o "\r" return
                exp_continue
            }
            "Enter Auth Username:" {
                send "$rbw_user\r"
                exp_continue
            }
            "Enter Auth Password:" {
                send "$rbw_pass\r"
                exp_continue
            }
            "CHALLENGE:" {
                send "p\r"
                exp_continue
            }
            "Initialization Sequence Completed" {
                set timeout -1
                interact
            }
            "FATAL:" {
                exit 1
            }
            timeout {
                exit 1
            }
            eof {
                exit 0
            }
        }
    }
  '';

  vpnScript = pkgs.writeShellScriptBin "vpn-launch" ''
    shopt -s nullglob
    DIRS=()
    for d in "${vpnDir}"/*/; do
      if [ -f "$d/client.ovpn" ] || [ -f "$d/.env" ]; then
        DIRS+=("$(basename "$d")")
      fi
    done

    if [ -n "$1" ]; then
      SELECTED="$1"
      VPN_DIR="${vpnDir}/$SELECTED"
    else
      if [ ''${#DIRS[@]} -eq 0 ]; then
        ${pkgs.libnotify}/bin/notify-send "VPN Error" "No VPN configurations found in ${vpnDir}"
        exit 1
      fi

      SELECTED=$(printf "%s\n" "''${DIRS[@]}" | ${pkgs.fzf}/bin/fzf --prompt="Select VPN Profile: ")
      if [ -z "$SELECTED" ]; then
        exit 1
      fi
      VPN_DIR="${vpnDir}/$SELECTED"
    fi

    ENV_FILE="$VPN_DIR/.env"
    if [ -f "$ENV_FILE" ]; then
      source "$ENV_FILE"
    fi
    TYPE=''${TYPE:-openvpn}

    if [ "$TYPE" = "openfortivpn" ]; then
      # ---- OpenFortiVPN ----

      if pgrep -f "openfortivpn.*$VPN_DIR" > /dev/null; then
        ${pkgs.libnotify}/bin/notify-send "VPN" "Stopping $SELECTED VPN..."
        sudo pkill -f "openfortivpn.*$VPN_DIR"
        echo "VPN stopped."
        exit 0
      fi

      if [ -n "$RBW_VPN_CONFIG" ]; then
        echo "Fetching credentials from rbw for '$RBW_VPN_CONFIG'..."
        RBW_USER=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field username 2>/dev/null)
        RBW_PASS=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" 2>/dev/null)
        RBW_HOST=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field host 2>/dev/null)
        [ -z "$RBW_HOST" ] && RBW_HOST=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field url 2>/dev/null)
        [ -z "$RBW_HOST" ] && RBW_HOST=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field gateway 2>/dev/null)
        [ -z "$RBW_HOST" ] && RBW_HOST=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field uris 2>/dev/null)
        RBW_PORT=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field port 2>/dev/null)
        [ -z "$RBW_PORT" ] && RBW_PORT=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field PORT 2>/dev/null)
        [ -z "$RBW_PORT" ] && RBW_PORT="443"
        RBW_REALM=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field realm 2>/dev/null)
        RBW_LOGIN_TYPE=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field LOGIN_TYPE 2>/dev/null)
        GATEWAY=''${GATEWAY:-$RBW_HOST}
        PORT=''${PORT:-$RBW_PORT}
        REALM=''${REALM:-$RBW_REALM}
        LOGIN_TYPE=''${LOGIN_TYPE:-$RBW_LOGIN_TYPE}
        if [ -n "$RBW_USER" ]; then USERNAME="$RBW_USER"; fi
        if [ -n "$RBW_PASS" ]; then PASSWORD="$RBW_PASS"; fi
      fi

      ${pkgs.libnotify}/bin/notify-send "VPN" "Starting $SELECTED VPN..."
      sudo -v || exit 1
      cd "$VPN_DIR" || exit 1

      REALM_ARG=""
      [ -n "$REALM" ] && REALM_ARG="--realm=$REALM"

      run_openfortivpn() {
        if [ -f "$VPN_DIR/config" ]; then
          sudo ${pkgs.openfortivpn}/bin/openfortivpn -c "$VPN_DIR/config"
        elif [ "$LOGIN_TYPE" = "SAML" ] && [ -n "$GATEWAY" ]; then
          sudo ${pkgs.openfortivpn}/bin/openfortivpn "$GATEWAY:$PORT" --saml-login
        elif [ -n "$GATEWAY" ] && [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
          echo "$PASSWORD" | sudo ${pkgs.openfortivpn}/bin/openfortivpn "$GATEWAY:$PORT" --username="$USERNAME" --password-on-stdin $REALM_ARG
        elif [ -n "$GATEWAY" ] && [ -n "$USERNAME" ]; then
          sudo ${pkgs.openfortivpn}/bin/openfortivpn "$GATEWAY:$PORT" --username="$USERNAME" $REALM_ARG
        else
          echo "Error: No config file or credentials for $SELECTED (GATEWAY='$GATEWAY', LOGIN_TYPE='$LOGIN_TYPE')"
          ${pkgs.libnotify}/bin/notify-send "VPN Error" "No config file or credentials for $SELECTED"
          exit 1
        fi
      }

      if [ -z "$VPN_BACKGROUND" ]; then
        run_openfortivpn
      else
        run_openfortivpn &
        for i in {1..30}; do
          if ip addr show dev ppp0 >/dev/null 2>&1; then
            echo "VPN connected."
            ${pkgs.libnotify}/bin/notify-send "VPN" "$SELECTED VPN Connected"
            break
          fi
          echo -n "."
          sleep 1
        done
        echo ""
        if ! ip addr show dev ppp0 >/dev/null 2>&1; then
          echo "VPN failed to connect."
          ${pkgs.libnotify}/bin/notify-send "VPN Error" "$SELECTED VPN failed to connect"
          exit 1
        fi
      fi
    else
      # ---- OpenVPN ----

      OPENVPN_CONF="$VPN_DIR/client.ovpn"
      if ! [ -f "$OPENVPN_CONF" ]; then
        ${pkgs.libnotify}/bin/notify-send "VPN Error" "No client.ovpn found in $VPN_DIR"
        exit 1
      fi

      if pgrep -f "openvpn.*$OPENVPN_CONF" > /dev/null; then
        if [ -z "$VPN_BACKGROUND" ]; then
          ${pkgs.libnotify}/bin/notify-send "VPN" "Stopping $SELECTED VPN..."
          sudo pkill -f "openvpn.*$OPENVPN_CONF"
          echo "VPN stopped."
          exit 0
        else
          ${pkgs.libnotify}/bin/notify-send "VPN" "Restarting $SELECTED VPN..."
          sudo pkill -f "openvpn.*$OPENVPN_CONF"
          sleep 1
        fi
      fi

      AUTH_ARGS=""
      CREDS_FILE=""
      if [ -n "$RBW_VPN_CONFIG" ]; then
        echo "Fetching credentials from rbw for '$RBW_VPN_CONFIG'..."
        RBW_USER=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" --field username 2>/dev/null)
        RBW_PASS=$(DISPLAY= ${pkgs.rbw}/bin/rbw get "$RBW_VPN_CONFIG" 2>/dev/null)
        if [ -n "$RBW_USER" ] && [ -n "$RBW_PASS" ]; then
          if [ "''${WGAUTH_MODE:-}" = "auto-push" ]; then
            AUTH_ARGS=""
          else
            CREDS_FILE=$(mktemp)
            echo "$RBW_USER" > "$CREDS_FILE"
            echo "$RBW_PASS" >> "$CREDS_FILE"
            if [ "''${WGAUTH_MODE:-}" = "interactive" ]; then
            AUTH_ARGS="--auth-user-pass $CREDS_FILE --auth-retry interact"
          else
            AUTH_ARGS="--auth-user-pass $CREDS_FILE"
          fi
        fi
      fi
    fi

      ${pkgs.libnotify}/bin/notify-send "VPN" "Starting $SELECTED VPN..."
      echo "Starting OpenVPN..."
      cd "$VPN_DIR" || exit 1

        if [ "''${WGAUTH_MODE:-}" = "auto-push" ]; then
          # ---- Auto-push mode (WatchGuard CRV1 challenge) ----
          if [ -z "''${RBW_USER:-}" ] || [ -z "''${RBW_PASS:-}" ]; then
            ${pkgs.libnotify}/bin/notify-send "VPN Error" "RBW_USER or RBW_PASS not set for auto-push mode"
            exit 1
          fi
          if [ -z "$VPN_BACKGROUND" ]; then
            ${vpnWgauth} "$OPENVPN_CONF" "$RBW_USER" "$RBW_PASS" "foreground"
          else
            # Background mode: runs expect backgrounded.
            # Expect uses sudo -S (password from file) to avoid interact,
            # then handles auth and CRV1 on the pty.
            # After ISC it stays alive (vwait forever) keeping pty open.
            cd "$VPN_DIR" || exit 1

            # Prompt for sudo password once on the real TTY
            SUDO_PASS_FILE=$(mktemp /tmp/vpn-sudo.XXXXXX)
            trap "rm -f '$SUDO_PASS_FILE'" EXIT
            read -s -p "[sudo] password for $USER: " SUDO_PASS
            echo ""
            echo "$SUDO_PASS" > "$SUDO_PASS_FILE"
            unset SUDO_PASS

            # Run expect in background, redirect output to a file for ISC detection
            EXPECT_OUTPUT=$(mktemp /tmp/vpn-expect.XXXXXX)
            trap "rm -f '$SUDO_PASS_FILE' '$EXPECT_OUTPUT'" EXIT
            export SUDO_PASS_FILE
            setsid ${vpnWgauth} "$OPENVPN_CONF" "$RBW_USER" "$RBW_PASS" "background" >"$EXPECT_OUTPUT" 2>&1 &
            EXPECT_PID=$!
            unset SUDO_PASS_FILE

            echo "Waiting for VPN (approve push notification on your phone)..."
            ISC_REACHED=0
            for i in {1..120}; do
              if grep -q "VPN_ISC_REACHED" "$EXPECT_OUTPUT" 2>/dev/null; then
                ISC_REACHED=1
                break
              fi
              if ! kill -0 $EXPECT_PID 2>/dev/null; then
                echo "Expect exited unexpectedly."
                cat "$EXPECT_OUTPUT"
                ${pkgs.libnotify}/bin/notify-send "VPN Error" "$SELECTED VPN failed to connect"
                rm -f "$SUDO_PASS_FILE" "$EXPECT_OUTPUT"
                exit 1
              fi
              echo -n "."
              sleep 1
            done
            echo ""

            if [ "$ISC_REACHED" = "0" ]; then
              echo "Timed out waiting for ISC."
              cat "$EXPECT_OUTPUT"
              ${pkgs.libnotify}/bin/notify-send "VPN Error" "$SELECTED VPN failed to connect"
              rm -f "$SUDO_PASS_FILE" "$EXPECT_OUTPUT"
              exit 1
            fi

            echo "VPN ISC reached, waiting for tunnel..."
            for i in {1..30}; do
              if ip addr show dev tun0 >/dev/null 2>&1 || ip addr show dev tun1 >/dev/null 2>&1; then
                echo "VPN connected."
                ${pkgs.libnotify}/bin/notify-send "VPN" "$SELECTED VPN Connected"
                break
              fi
              sleep 1
            done
            echo ""
            if ! ip addr show dev tun0 >/dev/null 2>&1 && ! ip addr show dev tun1 >/dev/null 2>&1; then
              echo "VPN failed to connect."
              ${pkgs.libnotify}/bin/notify-send "VPN Error" "$SELECTED VPN failed to connect"
              rm -f "$SUDO_PASS_FILE" "$EXPECT_OUTPUT"
              exit 1
            fi
            rm -f "$SUDO_PASS_FILE" "$EXPECT_OUTPUT"
          fi
      elif [ -z "$VPN_BACKGROUND" ]; then
        cleanup() {
          if [ -n "$AUTH_ARGS" ]; then
            rm -f "$CREDS_FILE"
          fi
        }
        trap cleanup EXIT
        sudo ${pkgs.openvpn}/bin/openvpn \
          --config "$OPENVPN_CONF" \
          $AUTH_ARGS \
          --data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305:AES-256-CBC
      else
        sudo ${pkgs.openvpn}/bin/openvpn \
          --config "$OPENVPN_CONF" \
          $AUTH_ARGS \
          --daemon \
          --data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305:AES-256-CBC

        echo "Waiting for VPN connection..."
        for i in {1..30}; do
          if ip addr show dev tun0 >/dev/null 2>&1 || ip addr show dev tun1 >/dev/null 2>&1; then
            echo "VPN connected."
            ${pkgs.libnotify}/bin/notify-send "VPN" "$SELECTED VPN Connected"
            break
          fi
          echo -n "."
          sleep 1
        done
        echo ""
        if ! ip addr show dev tun0 >/dev/null 2>&1 && ! ip addr show dev tun1 >/dev/null 2>&1; then
          echo "VPN failed to connect."
          ${pkgs.libnotify}/bin/notify-send "VPN Error" "$SELECTED VPN failed to connect"
          if [ -n "$AUTH_ARGS" ]; then
            rm -f "$CREDS_FILE"
          fi
          exit 1
        fi
        if [ -n "$AUTH_ARGS" ]; then
          (sleep 60 && rm -f "$CREDS_FILE") &
        fi
      fi
    fi
  '';
in {
  home.packages = [
    pkgs.expect
    pkgs.openvpn
    pkgs.openfortivpn
    pkgs.python3
    vpnScript
  ];

  home.activation.createVpnDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${vpnDir}"
  '';
}
