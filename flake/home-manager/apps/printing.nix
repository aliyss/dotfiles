{
  pkgs,
  lib,
  ...
}: let
  printerDir = "/home/aliyss/Documents/printers";

  # Generic SMB print queue setup. Site config lives under
  # ~/Documents/printers/<site>/.env so the repo stays free of site data.
  # Expected vars in .env:
  #   PRINTER_SERVER="print.example.com"
  #   PRINTER_SHARE="queue.example.com"
  #   PRINTER_DESC="Example queue (HP LaserJet 700 M712)"
  # Credentials are prompted and stored only in root-owned /etc/cups/printers.conf.
  printSetup = pkgs.writeShellScriptBin "printer-setup" ''
    set -euo pipefail

    SITE="''${1:-}"
    USERNAME="''${2:-}"

    # If only one arg given and it doesn't match a site dir, treat it as username
    if [ -n "$SITE" ] && [ ! -d "${printerDir}/$SITE" ] && [ -z "$USERNAME" ]; then
      USERNAME="$SITE"
      SITE=""
    fi

    if [ -z "$SITE" ]; then
      # Pick site if multiple exist, else use the single one, else error
      sites=$(ls -1 "${printerDir}" 2>/dev/null | tr '\n' ' ')
      count=$(ls -1 "${printerDir}" 2>/dev/null | wc -l)
      if [ "$count" -eq 0 ]; then
        echo "No printer configs found in ${printerDir}/<site>/.env" >&2
        echo "Create one, e.g. ${printerDir}/example/.env with PRINTER_SERVER/SHARE" >&2
        exit 1
      elif [ "$count" -eq 1 ]; then
        SITE=$(ls -1 "${printerDir}" | head -1)
      else
        SITE=$(printf "%s\n" ${printerDir}/*/ | xargs -n1 basename | ${pkgs.fzf}/bin/fzf --prompt="Select printer site: ")
        [ -z "$SITE" ] && exit 1
      fi
    fi

    ENV_FILE="${printerDir}/$SITE/.env"
    if [ ! -f "$ENV_FILE" ]; then
      echo "Missing $ENV_FILE — create it with PRINTER_SERVER, PRINTER_SHARE, PRINTER_DESC" >&2
      exit 1
    fi
    # shellcheck disable=SC1090
    set -a; source "$ENV_FILE"; set +a

    # No hardcoded fallback — repo must stay free of site data
    : "''${PRINTER_SERVER:?PRINTER_SERVER not set in $ENV_FILE}"
    : "''${PRINTER_SHARE:?PRINTER_SHARE not set in $ENV_FILE}"
    SERVER="$PRINTER_SERVER"
    SHARE="$PRINTER_SHARE"
    DESC="''${PRINTER_DESC:-$SHARE}"

    if [ -z "$USERNAME" ]; then
      printf 'Printer username: '
      read -r USERNAME
    fi
    [ -z "$USERNAME" ] && { echo "username required" >&2; exit 1; }

    # smbspool needs /etc/samba/smb.conf
    if [ ! -f /etc/samba/smb.conf ]; then
      echo "Creating minimal /etc/samba/smb.conf (required by smbspool)..."
      mkdir -p /etc/samba
      printf '[global]\n' > /etc/samba/smb.conf
    fi

    PPD=""
    for PPD in /nix/store/*-hplip-*/share/cups/model/HP/hp-laserjet_700_m712-ps.ppd.gz; do
      [ -e "$PPD" ] && break
      PPD=""
    done
    if [ -z "$PPD" ]; then
      echo "hplip PPD not found — rebuild with the printing module first." >&2
      exit 1
    fi

    printf 'Printer password for %s: ' "$USERNAME"
    trap "${pkgs.coreutils}/bin/stty echo 2>/dev/null" EXIT INT TERM
    ${pkgs.coreutils}/bin/stty -echo
    read -r PASSWORD
    ${pkgs.coreutils}/bin/stty echo
    trap - EXIT INT TERM
    echo

    enc() {
      printf '%s' "$1" | ${pkgs.perl}/bin/perl -pe 's/([^A-Za-z0-9_.!~*'"'"'()-])/sprintf("%%%02X", ord($1))/ge'
    }
    USER_ENC=$(enc "$USERNAME")
    PASS_ENC=$(enc "$PASSWORD")

    lpadmin -p "$SHARE" \
      -v "smb://$USER_ENC:$PASS_ENC@$SERVER/$SHARE" \
      -P "$PPD" \
      -D "$DESC" \
      -E

    for j in $(lpstat -W not-completed -o "$SHARE" 2>/dev/null | awk '{print $1}'); do
      lp -i "$j" -H resume 2>/dev/null || true
    done

    echo
    echo "Queue '$SHARE' ready. Jobs now print with the stored account ($SERVER)."
    echo "Manage jobs via: Print Jobs (launcher) or http://localhost:631"
    echo "Remove: sudo lpadmin -x $SHARE"
  '';

  printStatus = pkgs.writeShellScriptBin "printer-status" ''
    echo "=== printer ==="
    lpstat -p -d
    echo "=== jobs (all) ==="
    lpstat -W all -o
    echo "=== job details ==="
    lpstat -W all -o | awk '{print $1}' | while read -r j; do
      lpstat -l -o "$j" 2>/dev/null | grep -E "Status|Alerts" || true
    done
  '';

  printShares = pkgs.writeShellScriptBin "printer-shares" ''
    set -eu

    if [ "$EUID" -ne 0 ]; then
      echo "Run with sudo (it must read /etc/cups/printers.conf):" >&2
      echo "  sudo printer-shares" >&2
      exit 1
    fi

    URI=$(grep -o "smb://[^ <\"]*" /etc/cups/printers.conf | head -1)
    if [ -z "$URI" ]; then
      echo "No smb:// URI found in /etc/cups/printers.conf" >&2
      exit 1
    fi

    rest="''${URI#smb://}"
    userinfo="''${rest%%@*}"
    hostshare="''${rest#*@}"
    SHARE="''${hostshare#*/}"
    HOST="''${hostshare%%/*}"

    dec() { printf '%b' "''${1//%/\\x}"; }
    USER="$(dec "''${userinfo%%:*}")"
    PASS="$(dec "''${userinfo#*:}")"

    echo "Server: $HOST   (queue URI share: $SHARE)"
    echo
    ${pkgs.samba}/bin/smbclient -U "$USER%$PASS" -L "//$HOST" || true
  '';
in {
  home.packages = [
    printSetup
    printStatus
    printShares
  ];

  xdg.desktopEntries = {
    printer-setup = {
      name = "Printer Setup";
      genericName = "Printer Setup";
      comment = "Add SMB print queue (config in ~/Documents/printers/<site>/.env)";
      exec = "foot --title \"Printer Setup\" -e printer-setup";
      icon = "printer";
      terminal = false;
      categories = ["System" "Printing"];
    };
    printer-jobs = {
      name = "Print Jobs";
      genericName = "Print Management";
      comment = "View and manage print jobs via the CUPS web interface";
      exec = "${pkgs.xdg-utils}/bin/xdg-open http://localhost:631/jobs/";
      icon = "printer";
      terminal = false;
      categories = ["System" "Printing"];
    };
  };
}
