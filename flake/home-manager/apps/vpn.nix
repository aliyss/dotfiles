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
      # The forticlient dir is a first-class picker entry (added below only when
      # it exists), so skip it here to avoid listing it twice.
      [ "$(basename "$d")" = "forticlient" ] && continue
      if [ -f "$d/client.ovpn" ] || [ -f "$d/.env" ]; then
        DIRS+=("$(basename "$d")")
      fi
    done
    # FortiClient is shown in the picker only when the forticlient dir exists;
    # it holds the XML exports that fortivpn-import reads.
    if [ -d "${vpnDir}/forticlient" ]; then
      DIRS+=("forticlient")
    fi

    # FortiClient toggles via the native client. `fortivpn` resolves the tunnel
    # name (vpn list -> XML export) and auto-imports from the XML via
    # fortivpn-import if no profile is found, so `vpn-launch` just toggles.
    fortivpn_toggle() {
      if forticlient vpn status 2>/dev/null | grep -qE "Status: Connected"; then
        fortivpn down
      else
        fortivpn up
      fi
    }

    if [ -n "$1" ]; then
      SELECTED="$1"
      if [ "$SELECTED" = "forticlient" ]; then
        fortivpn_toggle
        exit $?
      fi
      VPN_DIR="${vpnDir}/$SELECTED"
    else
      if [ ''${#DIRS[@]} -eq 1 ]; then
        ${pkgs.libnotify}/bin/notify-send "VPN Error" "No VPN configurations found in ${vpnDir}"
        exit 1
      fi

      SELECTED=$(printf "%s\n" "''${DIRS[@]}" | ${pkgs.fzf}/bin/fzf --prompt="Select VPN Profile: ")
      if [ -z "$SELECTED" ]; then
        exit 1
      fi

      # FortiClient toggles via the native client; everything else is file-based.
      if [ "$SELECTED" = "forticlient" ]; then
        fortivpn_toggle
        exit $?
      fi
      VPN_DIR="${vpnDir}/$SELECTED"
    fi

    ENV_FILE="$VPN_DIR/.env"
    if [ -f "$ENV_FILE" ]; then
      source "$ENV_FILE"
    fi
    TYPE=''${TYPE:-openvpn}

    if [ "$TYPE" = "cisco" ]; then
      # ---- Cisco Secure Client (vendor client) ----
      # The only client that can complete SSO-v2 "Login window" (e.g. Microsoft MFA):
      # the NetworkManager openconnect plugin's dialog dies before it renders
      # (process_stdin assertion), and the openconnect CLI has no SSO handler at
      # all. Install/wrappers live in modules/services/cisco-secure-client.nix.
      #
      # The connect itself can only happen in the GUI: `vpn connect <host>`
      # answers
      #   >> error: The requested authentication type is not supported in
      #      AnyConnect CLI.
      # (that string lives in libvpnapi.so) because the gateway authenticates with
      # SAML/SSO, and only vpnui hands the login URL to the agent's webkit
      # window (acwebhelper). So: connect = open the client; state/disconnect are
      # fine over the CLI. Set CISCO_HOST in ~/Documents/vpn/<name>/.env.
      #
      # `vpn` is a `VPN>` REPL unless it reads commands from stdin with `-s`.
      # Match the state string exactly — a substring match on "connected" also
      # matches "state: Disconnected".
      CISCO_HOST=''${CISCO_HOST:-''${GATEWAY:-}} 
      if [ -z "$CISCO_HOST" ]; then
        echo "Error: CISCO_HOST (or GATEWAY) not set — add it to $ENV_FILE" >&2
        ${pkgs.libnotify}/bin/notify-send "VPN Error" "CISCO_HOST not set for $SELECTED (see $ENV_FILE)"
        exit 1
      fi
      if ! command -v cisco-vpn > /dev/null 2>&1 || ! command -v cisco-vpnui > /dev/null 2>&1; then
        ${pkgs.libnotify}/bin/notify-send "VPN Error" "Cisco Secure Client wrappers not found (see modules/services/cisco-secure-client.nix)"
        exit 1
      fi

      CISCO_STATE=$(printf 'state\n' | cisco-vpn -s 2>/dev/null | grep -o 'state: [A-Za-z]*' | tail -1)
      if [ "$CISCO_STATE" = "state: Connected" ]; then
        ${pkgs.libnotify}/bin/notify-send "VPN" "Disconnecting $CISCO_HOST..."
        printf 'disconnect\n' | cisco-vpn -s
        exit $?
      fi

      ${pkgs.libnotify}/bin/notify-send "VPN" "Opening Cisco Secure Client — click Connect, then complete the login + MFA"
      # setsid so the window outlives this script and its terminal.
      setsid cisco-vpnui > /dev/null 2>&1 &

      # ssh.nix and rdp.nix call this with VPN_BACKGROUND=1 and expect it to
      # block until the tunnel is up; the SSO step is the user's, in the GUI.
      if [ -n "$VPN_BACKGROUND" ]; then
        for i in {1..180}; do
          CISCO_STATE=$(printf 'state\n' | cisco-vpn -s 2>/dev/null | grep -o 'state: [A-Za-z]*' | tail -1)
          if [ "$CISCO_STATE" = "state: Connected" ]; then
            ${pkgs.libnotify}/bin/notify-send "VPN" "$CISCO_HOST Connected"
            exit 0
          fi
          sleep 2
        done
        ${pkgs.libnotify}/bin/notify-send "VPN Error" "$CISCO_HOST did not connect (SSO not completed?)"
        exit 1
      fi
      exit 0
    fi

    if [ "$TYPE" = "webauth" ] || [ "$TYPE" = "nm" ]; then
      # ---- AnyConnect WebAuth (NetworkManager + openconnect) ----
      # Generic SSO-v2 webview flow (NetworkManager + openconnect). The
      # connection and helper scripts belong to z10n-dev/nixos-anyconnect-webauth
      # (modules/core/networking.nix): `vpn-connect` deletes+recreates the
      # profile so every connect runs a fresh SSO instead of reusing an expired
      # cookie, then hands MFA to nm-applet's login window. TYPE=nm is an alias.
      # Define per-site in ~/Documents/vpn/<name>/.env:
      #   TYPE=nm
      #   NM_PROFILE=<name>        # or WEBAUTH_PROFILE
      #   # gateway lives in the NM profile or GATEWAY var; not hardcoded here.
      WA_PROFILE="''${WEBAUTH_PROFILE:-''${NM_PROFILE:-$SELECTED}}"

      if ! command -v vpn-connect > /dev/null 2>&1 || ! command -v vpn-disconnect > /dev/null 2>&1; then
        echo "Error: vpn-connect/vpn-disconnect not found — is services.anyconnect-webauth enabled?"
        ${pkgs.libnotify}/bin/notify-send "VPN Error" "vpn-connect not found (services.anyconnect-webauth)"
        exit 1
      fi

      NMCLI="${pkgs.networkmanager}/bin/nmcli"

      # The login window is a WebKitGTK view (nm-openconnect-auth-dialog), and
      # WebKitGTK does https through libsoup, which finds its TLS backend as a
      # GIO extension module (glib-networking). A session that started before
      # this was added to /etc/set-environment has a stale GIO_EXTRA_MODULES
      # without it, and then the window cannot load the SSO page at all — it
      # fails with libsoup's "TLS support is not available", which the clients
      # report as a login/authentication error. Prepend rather than default: the
      # variable may already exist and be missing exactly this module.
      export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"

      # nmcli has to reach the secret agent (nm-applet) over the session bus to
      # collect the SSO cookie; without it NetworkManager gives up with the
      # opaque "No valid secrets".
      if [ -z "''${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "/run/user/$(id -u)/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
      fi

      # Toggling off needs no SSO, so check the active state first.
      if [ "$("$NMCLI" -t -f GENERAL.STATE connection show "$WA_PROFILE" 2>/dev/null)" = "activated" ]; then
        ${pkgs.libnotify}/bin/notify-send "VPN" "Stopping $WA_PROFILE VPN..."
        vpn-disconnect "$WA_PROFILE"
        exit $?
      fi

      ${pkgs.libnotify}/bin/notify-send "VPN" "Starting $WA_PROFILE — complete the login + MFA in the window that opens"

      if [ -z "''${VPN_BACKGROUND:-}" ]; then
        vpn-connect "$WA_PROFILE"
        exit $?
      fi

      # ssh.nix and rdp.nix call this with VPN_BACKGROUND=1 and expect it to
      # block until the tunnel is up; the SSO/MFA step is the user's.
      setsid vpn-connect "$WA_PROFILE" > /dev/null 2>&1 &
      for i in {1..180}; do
        if [ "$("$NMCLI" -t -f GENERAL.STATE connection show "$WA_PROFILE" 2>/dev/null)" = "activated" ]; then
          ${pkgs.libnotify}/bin/notify-send "VPN" "$WA_PROFILE Connected"
          exit 0
        fi
        sleep 2
      done
      ${pkgs.libnotify}/bin/notify-send "VPN Error" "$WA_PROFILE did not connect (SSO not completed?)"
      exit 1
    fi

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
